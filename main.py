from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from streamlit_option_menu import option_menu
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
import pandas as pd
import seaborn as sns
import pymongo
import re
from pymongo.errors import DuplicateKeyError
from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
import streamlit as st
from pymongo.errors import CollectionInvalid
import mysql.connector
from functions2 import *

uri = "mongodb+srv://pranitakhade70:Pranit12345@cluster0.dwsodgl.mongodb.net/?retryWrites=true&w=majority"

# Create a new client and connect to the server
client = MongoClient(uri, server_api=ServerApi('1'))

# Send a ping to confirm a successful connection
try:
    client.admin.command('ping')
    #st.write("Pinged your deployment. You successfully connected to MongoDB!")
except Exception as e:
    st.write(e)

# Function to get or create session state
def get_session_state():
    if 'channel_stats' not in st.session_state:
        st.session_state.channel_stats = None

    if 'combined_data' not in st.session_state:
        st.session_state.combined_data = None

st.set_page_config(page_title= "Youtube Data Harvesting - Pranit Akhade",
                   layout= "wide",)

hide_default_format = """
       <style>
       #MainMenu {visibility: hidden; }
       footer {visibility: hidden;}
       </style>
       """
st.markdown(hide_default_format, unsafe_allow_html=True)

st.title("YouTube Data Harvesting & Warehousing")

selected = option_menu(None, ["Extract", "Migrate","Modify","FAQs"],
    default_index=0, icons = ["arrow-up-right-square-fill","arrow-down-up","pencil-square", "question-square-fill"],orientation="horizontal")

if selected == "Extract":
    # Main app code
    api_key = "AIzaSyAoO852prumBjkCwiBAP4YAkzVDkhHviEc"
    youtube = build("youtube", "v3", developerKey=api_key)
    channel_id = st.text_input("Enter Channel Id : ")

    # Check or initialize session state
    get_session_state()

    if st.button("Extract Data"):
        channel_stats = get_channel_stats(youtube, channel_id)
        playlist = get_playlist_ids(youtube, channel_id)
        video_ids = get_video_ids(youtube, upload_id(channel_stats))
        video_details = get_video_details(youtube,video_ids)
        combined_data = create_channel_data(channel_stats, playlist, video_details)
        st.session_state.channel_stats = channel_stats
        st.session_state.combined_data = combined_data
        st.write(combined_data)
        st.success("Data Extracted")

    if st.button("Store Data To MongoDB"):

        db = client['YouTube']

        # Get the collection name based on the channel name
        collection_name = st.session_state.channel_stats[0]['Channel_Name']

        # Get the collection (or create it if it doesn't exist)
        records = db[collection_name]

        # Check if the data already exists
        existing_data = records.find_one({"_id": st.session_state.combined_data["_id"]})

        if existing_data:
            st.warning("Data for this channel ID already exists in the database.")

        else:
            # Insert the data into MongoDB
            records.insert_one(st.session_state.combined_data)
            st.success("Data Stored to MongoDB Database")

if selected == "Migrate":

    st.subheader("Migrate Data From MongoDB to SQL")
    # Assuming 'client' is a MongoDB client object
    db = client['YouTube']

    collection_names = db.list_collection_names()

    create_tables()

    if not collection_names:
        st.write("MongoDB Database has no Data")

    else:
        try:
            # Connect to SQL database
            mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database='youtube'

            )
            mycursor = mydb.cursor(buffered=True)


            # Fetch channel names from SQLite
            mycursor.execute("""SELECT channel_name FROM Channel""")
            channel_names = [item[0] for item in mycursor.fetchall()]

            # Create a new list with MongoDB collections not present in SQLite
            missing_collections = [collection for collection in collection_names if collection not in channel_names]

            selected_collection_name = st.selectbox('Select the collection to Migrate to SQL', missing_collections)

        except sqlite3.Error as e:
            pass
            #st.error(f"Error accessing the database: {e}")

        finally:
            mycursor.close()
            mydb.close()

    if st.button("Migrate to SQL"):
        # Get the MongoDB collection object based on the selected collection name
        records = db[selected_collection_name]

        # Retrieve the _id of the first document in the selected collection
        channel_id = records.find_one({})['_id']

        mongo_data = records.find({"_id": channel_id})

        # Extract channel information using the 'extract_channel' function
        channel = extract_channel(records, channel_id)
        playlist = extract_playlist(records, channel_id)
        videos = extract_videos(records, channel_id)
        comment = extract_comment(records, channel_id)

        mydb = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database='youtube'

        )
        mycursor = mydb.cursor(buffered=True)

        insert_channel_data(channel, mycursor, mydb)
        insert_playlist_data(channel, playlist, mycursor, mydb)
        insert_video_data(channel, videos, mycursor, mydb)
        insert_comment_data(comment, mycursor, mydb)
        close_connection(mycursor, mydb)

        # Commit the changes and close the connection
        st.success("Migrated to SQL")

        # Display the data inserted into SQLite using Streamlit
        #st.write("Data Inserted into SQLite")

    st.subheader("Delete Data From MongoDB")

    db = client['YouTube']
    # Get a list of collection names in the 'YouTube' database
    collection_names = db.list_collection_names()
    # Create a Streamlit selectbox to choose a collection for migration
    selected_collection_name = st.selectbox('', collection_names, key="unique_key_for_selectbox")
    st.write(f"Do you really wish to delete {selected_collection_name} data from MongoDB Database")

    if st.button("Confirm Delete"):
        try:
            db[selected_collection_name].drop()
            st.write(f"Collection '{selected_collection_name}' deleted successfully.")
        except CollectionInvalid as e:
            st.write(f"Error: {e}")

if selected == "Modify":
    st.header("SQL Data")
    selected_table = st.selectbox("Select a table", ["Channel", "Playlist", "Video", "Comment"], index=0)

    # Mapping of table names to subheaders
    table_subheaders = {
        "Channel": "Channel Data",
        "Playlist": "Playlist Data",
        "Video": "Video Data",
        "Comment": "Comment Data",
    }

    if selected_table in table_subheaders:
        subheader_text = table_subheaders[selected_table]
        #st.subheader(subheader_text)
        try:
            mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database='youtube'

            )
            mycursor = mydb.cursor(buffered=True)

            # Using a parameterized query to avoid SQL injection
            query = f"SELECT * FROM {selected_table}"
            mycursor.execute(query)

            data = mycursor.fetchall()

            if data:
                st.table(data)
            else:
                st.warning("No data available for the selected table.")

        except sqlite3.Error as e:
            st.error("No Data in SQL")

        finally:
            mydb.close()

    else:
        st.warning("Please select a valid table.")

    st.header("DELETE DATA")
    try:
        mydb = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database='youtube'

        )
        mycursor = mydb.cursor(buffered=True)

        # Query to retrieve channel names from the Channel table
        select_query = "SELECT channel_name FROM Channel"

        # Execute the query
        mycursor.execute(select_query)

        # Fetch all the channel names
        channel_names = mycursor.fetchall()

        if channel_names:
            channel_names_list = [name[0] for name in channel_names]

            selected_channel = st.selectbox("Select a table", channel_names_list, index=0)

            st.write(f"Do you want to delete all data of '{selected_channel}' from all tables.")

            if st.button("Confirm Delete"):

                delete_channel_data(selected_channel, mycursor, mydb)
                delete_playlist_data(selected_channel, mycursor, mydb)
                delete_video_data(selected_channel, mycursor, mydb)
                delete_comment_data(selected_channel, mycursor, mydb)
                close_connection(mycursor, mydb)
                st.write(f"Data related to the channel with name '{selected_channel}' deleted from all tables.")
        else:
            st.write("No channel names available.")

    except sqlite3.Error as e:
        st.write(f"Error accessing the database: {e}")

if selected == "FAQs":
    try:
        mydb = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database='youtube'

        )
        mycursor = mydb.cursor(buffered=True)

        queries_options = [
            "What are the names of all the videos and their corresponding channels?",
            "Which channels have the most number of videos, and how many videos do they have?",
            "What are the top 10 most viewed videos and their respective channels?",
            "How many comments were made on each video, and what are their corresponding video names?",
            "Which videos have the highest number of likes, and what are their corresponding channel names?",
            "What is the total number of likes and dislikes for each video, and what are their corresponding video names?",
            "What is the total number of views for each channel, and what are their corresponding channel names?",
            "What are the names of all the channels that have published videos in the year 2022?",
            "What is the average duration of all videos in each channel, and what are their corresponding channel names?",
            "Which videos have the highest number of comments, and what are their corresponding channel names"
        ]
        selected_query = st.selectbox("Select a query", queries_options)
        execute_and_display_query(selected_query, mycursor)
        mydb.close()
    except mysql.connector.Error as e:
        st.error("No Data in SQL")