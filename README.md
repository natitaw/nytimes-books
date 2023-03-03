<h1 align="center">Welcome to NYTimes Books API Project: Retrieving Book Lists and Books Data 👋</h1>
<p>
</p>

## Author

👤 **Nate Shenkute**

* Website: [natitaw.com](https://natitaw.com)
* Github: [@natitaw](https://github.com/natitaw)
* LinkedIn: [@natitaw](https://linkedin.com/in/natitaw)


 This GitHub page provides a project that involves working with the NYTimes Books API to retrieve data on book lists and books. The project includes two main tasks:
 1.  Using the API endpoint /lists/names.json to find the 5 newest monthly lists and output list_name_encoded and oldest_published_date for all 5 lists in a single JSON file.  
	1.1 This task is automated using GitHub Actions. The YAML file can be found in the 'Actions' tab or by clicking [here](https://github.com/natitaw/nytimes-books/blob/main/.github/workflows/nightly-update.yml)
		- Note: The workflow is currently manually disabled 
 2.  Writing a script that accepts the path to the JSON file from the first task, as well as an optional end date, and retrieves the books in each list for the specified date range. The output is a single NDJson file per list containing the entire API response for all months in that list.
    
 This project can be useful for anyone who wants to work with the NYTimes Books API to retrieve data on books and book-related content from The New York Times. The code and documentation on the GitHub page can serve as a helpful starting point for anyone looking to build similar projects or integrate the NYTimes Books API into their own applications.


## Getting Started

Here is how you can install and run the file

1. Get a free API Key at the [NYTimes Dev Portal](https://developer.nytimes.com/get-started)
2. Clone the repo
   ```sh
   git clone https://github.com/natitaw/nytimes-books.git
   ```
3. Install pip packages
   ```sh
   pip install -r requirements.txt
   ```
4. Enter your API in `config.py`
   ```js
   API_KEY = 'ENTER_YOUR_API'
   ```
-	*Note: since this is a private repo, I have already done step (4) so you can skip it*
---




 ## Part 1: Extract

 ## Part 2: Load
This part is about the load part of the assignment. 

Things to consider
- Setup for the CLI
-  [Semi-structured Data Size Limitations](https://docs.snowflake.com/en/user-guide/data-load-considerations-prepare#semi-structured-data-size-limitations "Permalink to this headline"). What to consider when uploading NDJSON files?


Firstly, I created a database called `NATURAL_CYCLES`. Then I created a table called `RAW_BOOKS` using the following command:

```SQL
USE DATABASE NATURAL_CYCLES;

CREATE TABLE RAW_BOOKS (
    SRC_JSON VARIANT
    );
```

Then the next step is to upload the files into the table. This consists of two steps:
1. Upload (i.e. stage) the files to a Snowflake named stage using the `PUT` command
2. Load the contents of the staged files into the Snowflake database `NATURAL_CYCLES` using the command `COPY INTO`

## Part 3: Transform


