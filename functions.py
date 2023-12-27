from googleapiclient.errors import HttpError
from pymongo import MongoClient
import pandas as pd
import pymongo
import re
import streamlit as st
import mysql.connector

def convert_duration(duration):
    match = re.match(r'PT(\d+H)?(\d+M)?(\d+S)?', duration)
    if not match:
        return '00:00:00'

    hours, minutes, seconds = (int(match.group(i)[:-1]) if match.group(i) else 0 for i in [1, 2, 3])
    total_seconds = hours * 3600 + minutes * 60 + seconds
    return '{:02d}:{:02d}:{:02d}'.format(total_seconds // 3600, (total_seconds % 3600) // 60, total_seconds % 60)

# Function to get channel stats
def get_channel_stats(youtube, channel_id):
    all_data = []
    request = youtube.channels().list(
        part="snippet,contentDetails,statistics",
        id=channel_id)
    response = request.execute()

    data1 = dict(Channel_Name=response['items'][0]['snippet']['title'],
                 Channel_Id=response['items'][0]['id'],
                 Subscription_Count=response['items'][0]['statistics']['subscriberCount'],
                 Channel_Views=response['items'][0]['statistics']['viewCount'],
                 Channel_Description=response['items'][0]['snippet']['description'],
                 Upload_Id=response['items'][0]["contentDetails"]["relatedPlaylists"]["uploads"])

    all_data.append(data1)
    return all_data

def channel_name(channel_stats):
  channel = channel_stats[0]['Channel_Name']
  return channel

def upload_id(channel_stats):
  playlist = channel_stats[0]['Upload_Id']
  return playlist

def get_playlist_ids(youtube, channel_id):
  request = youtube.playlists().list(
        part="snippet",
        channelId=channel_id,
        maxResults=50
    )
  response = request.execute()

  playlist_ids = []
  for i in range(len(response['items'])):
    playlist = dict(playlist_id = response['items'][i]['id'],
                    channel = response['items'][i]['snippet']['channelId'],
                    playlist_name = response['items'][i]['snippet']['title']
                  )
    playlist_ids.append(playlist)

  next_page_token = response.get('nextPageToken')
  more_pages = True
  while more_pages:
    if next_page_token is None:
      more_pages = False
    else:
      request = youtube.playlists().list(
        part="snippet",
        channelId=channel_id,
        maxResults=50
      )
      response = request.execute()

      for i in range(len(response['items'])):
        playlist = dict(playlist_id = response['items'][i]['id'],
                    channel = response['items'][i]['snippet']['channelId'],
                    playlist_name = response['items'][i]['snippet']['title']
                  )
        playlist_ids.append(playlist)
      next_page_token = response.get('nextPageToken')


  return playlist_ids

def get_video_ids(youtube, upload_id):

  request = youtube.playlistItems().list(
        part = 'contentDetails',
        playlistId = upload_id,
        maxResults = 50
        )
  response = request.execute()

  video_ids = []
  for i in range(len(response['items'])):
    video_ids.append(response['items'][i]['contentDetails']['videoId'])

  next_page_token = response.get('nextPageToken')
  more_pages = True
  while more_pages:
    if next_page_token is None:
      more_pages = False
    else:
      request = youtube.playlistItems().list(
            part = 'contentDetails',
            playlistId = upload_id,
            maxResults = 50,
            pageToken = next_page_token)
      response = request.execute()

      for i in range(len(response['items'])):
        video_ids.append(response['items'][i]['contentDetails']['videoId'])

      next_page_token = response.get('nextPageToken')

  return video_ids

def get_comments_details(youtube, video_id):
    all_comments_data = []

    try:
        next_page_token = None
        more_pages = True

        while more_pages:
            request = youtube.commentThreads().list(
                part="snippet",
                videoId=video_id,
                maxResults=100,
                pageToken=next_page_token
            )
            response = request.execute()

            for comment in response.get('items', []):
                comments_data = {
                    'comment_id': comment['id'],
                    'comment_text': comment['snippet']['topLevelComment']['snippet']['textDisplay'],
                    'comment_author': comment['snippet']['topLevelComment']['snippet']['authorDisplayName'],
                    'comment_published_at': comment['snippet']['topLevelComment']['snippet']['publishedAt']
                }
                all_comments_data.append(comments_data)

            next_page_token = response.get('nextPageToken')
            more_pages = next_page_token is not None

    except HttpError as e:
        if e.resp.status == 403:
            error_content = e.content.decode('utf-8')
            if "commentsDisabled" in error_content:
                pass  # Comments are disabled for the video with ID: video_id
        else:
            raise

    return all_comments_data

def get_video_details(youtube, video_ids):
    all_video_stats = []

    for i in range(0, len(video_ids), 50):
        request = youtube.videos().list(
            part="snippet,contentDetails,statistics",
            id=",".join(video_ids[i:i+50])
        )
        response = request.execute()

        for video in response['items']:
            Video_Id = video['id']
            comments_details = get_comments_details(youtube, Video_Id)
            video_stats = {
                'Video_Id': video['id'],
                'Video_Name': video['snippet']['title'],
                'Video_Description': video['snippet']['description'],
                'Tags': video['snippet'].get('tags'),
                'PublishedAt': video['snippet']['publishedAt'],
                'View_Count': video['statistics']['viewCount'],
                'Like_Count': video['statistics'].get('likeCount'),
                'Dislike_Count': video['statistics'].get('dislikeCount'),
                'Favorite_Count': video['statistics']['favoriteCount'],
                'Comment_Count': video['statistics'].get('commentCount'),
                'Duration': convert_duration(video['contentDetails']['duration']),
                'Thumbnail': video['snippet']['thumbnails']['default']['url'],
                'Caption_Status': video['contentDetails']['caption'],
                'Comments': comments_details
            }
            all_video_stats.append(video_stats)

    return all_video_stats

def extract_channel(records, channel_id):
    mongo_data = records.find({"_id": channel_id})
    channel_info = []
    for data in mongo_data:
      ch_info = dict(
          channel_id = data['Channel_Name']['Channel_Id'],
          channel_name = data['Channel_Name']['Channel_Name'],
          channel_type = 'YouTube',
          channel_views = data['Channel_Name']['Channel_Views'],
          channel_description = data['Channel_Name']['Channel_Description'],
          upload_id = data['Channel_Name']['Upload_Id'],
          )
      channel_info.append(ch_info)
    return channel_info

def extract_playlist(records, channel_id):
    mongo_data = records.find({"_id": channel_id})
    playlist = []

    for data in mongo_data:
        play = data.get('Playlist', {})  # Initialize play as an empty dictionary if 'Playlist' key is missing
        for playlist_key, playlist_data in play.items():
            if playlist_key.startswith("Playlist_Id"):
                entry = {
                    'Playlist_Id': playlist_data.get('Playlist_Id'),
                    'Channel_Id': playlist_data.get('Channel_Id'),
                    'Playlist_Name': playlist_data.get('Playlist_Name')
                }
                playlist.append(entry)

    return playlist

def extract_videos(records, channel_id):
  video_details = []
  mongo_data = records.find({"_id": channel_id})
  for data in mongo_data:
      playlist_id = data['Channel_Name']['Upload_Id']
      for video_key, video_data in data.items():
        if video_key.startswith("Video_Id_"):
          video_ids = video_data.get('Video_Id')
          video_name = video_data.get('Video_Name')
          video_description = video_data.get('Video_Description')
          published_date = video_data.get('PublishedAt')
          view_count = video_data.get('View_Count')
          like_count = video_data.get('Like_Count')
          dislike_count = video_data.get('Dislike_Count')
          favorite_count = video_data.get('Favorite_Count')
          comment_count = video_data.get('Comment_Count')
          duration = video_data.get('Duration')
          thumbnail = video_data.get('Thumbnail')
          caption_status = video_data.get('Caption_Status')

          video_info = {
              'video_id': video_ids,
              'video_name': video_name,
              'video_description': video_description,
              'published_date': published_date,
              'view_count': view_count,
              'like_count': like_count,
              'dislike_count': dislike_count,
              'favorite_count': favorite_count,
              'comment_count': comment_count,
              'duration': duration,
              'thumbnail': thumbnail,
              'caption_status': caption_status,

          }
          video_details.append(video_info)

  return video_details


def extract_comment(records, channel_id):
    comment_details = []
    mongo_data = records.find({"_id": channel_id})
    for data in mongo_data:
        for video_key, video_data in data.items():
          if video_key.startswith("Video_Id_"):
            video_ids = video_data.get('Video_Id')
            comments = video_data.get('Comments', {})  # Retrieve comments dictionary, default to empty if no comments

            # Accessing comments for each video
            for comment_key, comment_data in comments.items():
              if comment_key.startswith("Comment_Id_"):
                comment_info = {
                    'video_id': video_ids,
                    'comment_id': comment_data['Comment_Id'],
                    'comment_text': comment_data['Comment_Text'],
                    'comment_author': comment_data['Comment_Author'],
                    'comment_published_at': comment_data['Comment_PublishedAt']
                }
                comment_details.append(comment_info)

    return comment_details

def create_channel_data(channel_stats, playlist, video_details):
    combined_data = {}
    combined_data["_id"] = channel_stats[0]['Channel_Id']
    add_channel_details(combined_data, channel_stats)
    add_playlists(combined_data, playlist)
    add_videos(combined_data, video_details)
    return combined_data

def add_channel_details(combined_data, channel_stats):
    channel_details = channel_stats[0]
    combined_data["Channel_Name"] = {
        "Channel_Name": channel_details['Channel_Name'],
        "Channel_Id": channel_details['Channel_Id'],
        "Subscription_Count": int(channel_details['Subscription_Count']),
        "Channel_Views": int(channel_details['Channel_Views']),
        "Channel_Description": channel_details['Channel_Description'],
        "Upload_Id": channel_details['Upload_Id']
    }

def add_playlists(combined_data, playlist):
    combined_data["Playlist"] = {}
    for i, playlist_info in enumerate(playlist, start=1):
        combined_data["Playlist"]["Playlist_Id_" + str(i)] = {
            "Playlist_Id": playlist_info.get("playlist_id"),
            "Channel_Id": playlist_info.get("channel"),
            "Playlist_Name": playlist_info.get("playlist_name"),
        }

def add_videos(combined_data, video_details):
    for i, video_info in enumerate(video_details, start=1):
        combined_data['Video_Id_' + str(i)] = {
            "Video_Id": video_info['Video_Id'],
            "Video_Name": video_info['Video_Name'],
            "Video_Description": video_info['Video_Description'],
            "Tags": video_info['Tags'],
            "PublishedAt": video_info['PublishedAt'],
            "View_Count": int(video_info['View_Count']) if video_info['View_Count'] is not None else 0,
            "Like_Count": int(video_info['Like_Count']) if video_info['Like_Count'] is not None else 0,
            "Dislike_Count": video_info['Dislike_Count'],
            "Favorite_Count": int(video_info['Favorite_Count']) if video_info['Favorite_Count'] is not None else 0,
            "Comment_Count": int(video_info['Comment_Count']) if video_info['Comment_Count'] is not None else 0,
            "Duration": video_info['Duration'],
            "Thumbnail": video_info['Thumbnail'],
            "Caption_Status": video_info['Caption_Status'],
            "Comments": {}
        }
        add_comments(combined_data, i, video_info['Comments'])

def add_comments(combined_data, video_index, comments):
    for j, comment in enumerate(comments, start=1):
        comment_id_str = 'Comment_Id_' + str(j)
        combined_data['Video_Id_' + str(video_index)]["Comments"][comment_id_str] = {
            "Comment_Id": comment['comment_id'],
            "Comment_Text": comment['comment_text'],
            "Comment_Author": comment['comment_author'],
            "Comment_PublishedAt": comment['comment_published_at']
        }

def create_tables():
    mydb = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database='youtube'

    )
    mycursor = mydb.cursor(buffered=True)

    create_channel_table(mycursor)
    create_playlist_table(mycursor)
    create_video_table(mycursor)
    create_comment_table(mycursor)

    mydb.commit()
    mydb.close()

def create_channel_table(mycursor):
    mycursor.execute('''
        CREATE TABLE IF NOT EXISTS Channel (
            channel_id VARCHAR(255) PRIMARY KEY,
            channel_name VARCHAR(255),
            channel_type VARCHAR(255),
            channel_views INTEGER,
            channel_description TEXT,
            upload_id VARCHAR(255)
        )
    ''')

def create_playlist_table(mycursor):
    mycursor.execute('''
        CREATE TABLE IF NOT EXISTS Playlist (
            playlist_id VARCHAR(255) PRIMARY KEY,
            channel_id VARCHAR(255) REFERENCES Channel(channel_id),
            playlist_name VARCHAR(255),
            upload_id VARCHAR(255)
        )
    ''')

def create_video_table(mycursor):
    mycursor.execute('''
        CREATE TABLE IF NOT EXISTS Video (
            video_id VARCHAR(255) PRIMARY KEY,
            video_name TEXT,
            video_description VARCHAR(255),
            published_date DATETIME,
            view_count INT,
            like_count INT,
            dislike_count INT,
            favorite_count INT,
            comment_count INT,
            duration INT,
            thumbnail VARCHAR(255),
            caption_status VARCHAR(255),
            upload_id VARCHAR(255) REFERENCES Playlist(upload_id)
        )
    ''')

def create_comment_table(mycursor):
    mycursor.execute('''
        CREATE TABLE IF NOT EXISTS Comment (
            comment_id VARCHAR(255) PRIMARY KEY,
            video_id VARCHAR(255) REFERENCES Video(video_id),
            comment_text TEXT,
            comment_author VARCHAR(255),
            comment_published_date DATETIME
        )
    ''')

def insert_channel_data(channel, mycursor, mydb):
    insert_query = '''
        INSERT INTO Channel (channel_id, channel_name, channel_type, channel_views, channel_description, upload_id)
        VALUES (%s, %s, %s, %s, %s, %s)
    '''

    channel_data = channel[0]
    insert_values = (
        channel_data['channel_id'],
        channel_data['channel_name'],
        channel_data['channel_type'],
        channel_data['channel_views'],
        channel_data['channel_description'],
        channel_data['upload_id']
    )

    mycursor.execute(insert_query, insert_values)
    mydb.commit()

def insert_playlist_data(channel, playlist, mycursor, mydb):
    insert_query = '''
        INSERT INTO Playlist (playlist_id, channel_id, playlist_name, upload_id)
        VALUES (%s, %s, %s, %s)
    '''

    insert_values = [(playlist_data['Playlist_Id'], playlist_data['Channel_Id'], playlist_data['Playlist_Name'], channel[0]['upload_id']) for playlist_data in playlist]

    for values in insert_values:
        mycursor.execute(insert_query, values)
        mydb.commit()

def insert_video_data(channel, videos, mycursor, mydb):
    insert_query = '''
        INSERT INTO Video (video_id, video_name, video_description, published_date, view_count, like_count, dislike_count, favorite_count, comment_count, duration, thumbnail, caption_status, upload_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    '''

    insert_values = [
        (data['video_id'], data['video_name'], data['video_description'], data['published_date'], data['view_count'],
         data['like_count'], data['dislike_count'], data['favorite_count'], data['comment_count'], data['duration'],
         data['thumbnail'], data['caption_status'], channel[0]['upload_id']) for data in videos
    ]

    for values in insert_values:
        mycursor.execute(insert_query, values)
        mydb.commit()

def insert_comment_data(comment, mycursor, mydb):
    insert_query = '''
        INSERT INTO Comment (comment_id, video_id, comment_text, comment_author, comment_published_date)
        VALUES (%s, %s, %s, %s, %s)
    '''

    insert_values = [
        (data['comment_id'], data['video_id'], data['comment_text'], data['comment_author'], data['comment_published_at'])
        for data in comment
    ]

    for values in insert_values:
        comment_id = values[0]
        mycursor.execute("SELECT comment_id FROM Comment WHERE comment_id = %s", (comment_id,))
        existing_comment = mycursor.fetchone()

        if not existing_comment:
            mycursor.execute(insert_query, values)
            mydb.commit()

def delete_channel_data(selected_channel, mycursor, mydb):
    delete_channel_query = "DELETE FROM Channel WHERE channel_name = %s"
    mycursor.execute(delete_channel_query, (selected_channel,))
    mydb.commit()

def delete_playlist_data(selected_channel, mycursor, mydb):
    delete_playlist_query = "DELETE FROM Playlist WHERE channel_id IN (SELECT channel_id FROM Channel WHERE channel_name = %s)"
    mycursor.execute(delete_playlist_query, (selected_channel,))
    mydb.commit()

def delete_video_data(selected_channel, mycursor, mydb):
    delete_video_query = "DELETE FROM Video WHERE upload_id IN (SELECT upload_id FROM Playlist WHERE channel_id IN (SELECT channel_id FROM Channel WHERE channel_name = %s))"
    mycursor.execute(delete_video_query, (selected_channel,))
    mydb.commit()

def delete_comment_data(selected_channel, mycursor, mydb):
    delete_comment_query = "DELETE FROM Comment WHERE video_id IN (SELECT video_id FROM Video WHERE upload_id IN (SELECT upload_id FROM Playlist WHERE channel_id IN (SELECT channel_id FROM Channel WHERE channel_name = %s)))"
    mycursor.execute(delete_comment_query, (selected_channel,))
    mydb.commit()

def close_connection(mycursor, mydb):
    mycursor.close()
    mydb.close()


def execute_query_and_display_results(query, mycursor):
    mycursor.execute(query)
    results = mycursor.fetchall()
    df = pd.DataFrame(results)
    st.dataframe(df)

def execute_and_display_query(selected_query, mycursor):
    if selected_query == "What are the names of all the videos and their corresponding channels?":
        query = """
            SELECT
                DISTINCT Video.video_id AS VideoID,
                Channel.channel_name AS ChannelName,
                Video.video_name AS VideoName
            FROM
                Video
            JOIN
                Playlist ON Video.upload_id = Playlist.upload_id
            JOIN
                Channel ON Playlist.channel_id = Channel.channel_id;
        """
        execute_query_and_display_results(query, mycursor)

    elif selected_query == "Which channels have the most number of videos, and how many videos do they have?":
        query = """
            SELECT
                Channel.channel_name AS ChannelName,
                COUNT(DISTINCT video_id) AS VideoCount
            FROM
                Channel
            JOIN
                Playlist ON Channel.channel_id = Playlist.channel_id
            JOIN
                Video ON Playlist.upload_id = Video.upload_id
            GROUP BY
                Channel.channel_name
            ORDER BY
                VideoCount DESC;
        """
        execute_query_and_display_results(query, mycursor)

    elif selected_query == "What are the top 10 most viewed videos and their respective channels?":
        query = """
            SELECT
                DISTINCT Video.video_id AS VideoID,
                Video.video_name AS VideoName,
                Channel.channel_name AS ChannelName,
                Video.view_count AS ViewCount
            FROM
                Video
            JOIN
                Playlist ON Video.upload_id = Playlist.upload_id
            JOIN
                Channel ON Playlist.channel_id = Channel.channel_id
            ORDER BY
                ViewCount DESC
            LIMIT 10;
        """
        execute_query_and_display_results(query, mycursor)

    elif selected_query == "How many comments were made on each video, and what are their corresponding video names?":
        query = """
            SELECT
                Video.video_name AS VideoName,
                Video.video_id AS VideoID,
                COUNT(Comment.comment_id) AS CommentCount
            FROM
                Video
            LEFT JOIN
                Comment ON Video.video_id = Comment.video_id
            GROUP BY
                Video.video_id, Video.video_name
            ORDER BY
                CommentCount DESC;
        """
        execute_query_and_display_results(query, mycursor)

    elif selected_query == "Which videos have the highest number of likes, and what are their corresponding channel names?":
        query = """
            SELECT
                DISTINCT Video.video_id AS VideoID,
                Video.video_name AS VideoName,
                Channel.channel_name AS ChannelName,
                Video.like_count AS LikeCount
            FROM
                Video
            JOIN
                Playlist ON Video.upload_id = Playlist.upload_id
            JOIN
                Channel ON Playlist.channel_id = Channel.channel_id
            ORDER BY
                Video.like_count DESC
            LIMIT 10;
        """
        execute_query_and_display_results(query, mycursor)

    elif selected_query == "What is the total number of likes and dislikes for each video, and what are their corresponding video names?":
        query = """
            SELECT
                Video.video_name AS VideoName,
                SUM(Video.like_count) AS TotalLikes,
                SUM(Video.dislike_count) AS TotalDislikes
            FROM
                Video
            GROUP BY
                Video.video_name
            ORDER BY
                TotalLikes DESC;
        """

        execute_query_and_display_results(query, mycursor)

    elif selected_query == "What is the total number of views for each channel, and what are their corresponding channel names?":
        query = """
            SELECT
                Channel.channel_name,
                SUM(Video.view_count) AS total_views
            FROM
                Channel
            JOIN
                Playlist ON Channel.channel_id = Playlist.channel_id
            JOIN
                Video ON Playlist.upload_id = Video.upload_id
            GROUP BY
                Channel.channel_name;
        """
        execute_query_and_display_results(query, mycursor)



    elif selected_query == "What are the names of all the channels that have published videos in the year 2022?":

        query = """
            SELECT DISTINCT
                Channel.channel_name AS ChannelName
            FROM
                Channel
            JOIN
                Playlist ON Channel.channel_id = Playlist.channel_id
            JOIN
                Video ON Playlist.upload_id = Video.upload_id
            WHERE
                strftime('%Y', Video.published_date) = '2022';
        """

        execute_query_and_display_results(query, mycursor)

    elif selected_query == "What is the average duration of all videos in each channel, and what are their corresponding channel names?":
        # Execute the SQL query
        query = """
            SELECT
                Channel.channel_name AS ChannelName,
                AVG(Video.duration) AS AverageDuration
            FROM
                Channel
            JOIN
                Playlist ON Channel.channel_id = Playlist.channel_id
            JOIN
                Video ON Playlist.upload_id = Video.upload_id
            GROUP BY
                Channel.channel_name;
        """

        execute_query_and_display_results(query, mycursor)

    elif selected_query == "Which videos have the highest number of comments, and what are their corresponding channel names":
        query = """
            SELECT
                Video.video_name AS VideoName,
                Channel.channel_name AS ChannelName,
                COUNT(Comment.comment_id) AS CommentCount
            FROM
                Video
            JOIN
                Playlist ON Video.upload_id = Playlist.upload_id
            JOIN
                Channel ON Playlist.channel_id = Channel.channel_id
            LEFT JOIN
                Comment ON Video.video_id = Comment.video_id
            GROUP BY
                Video.video_id, Video.video_name, Channel.channel_name
            ORDER BY
                CommentCount DESC
            LIMIT 10;
        """
        execute_query_and_display_results(query, mycursor)

    else:
        st.error("Invalid query selection. Please choose a valid query.")


