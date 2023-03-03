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


Firstly, I created a database called `NATURAL_CYCLES` using the UI of Snowflake. Then I created a table called `RAW_BOOKS` using the following command:

```SQL
USE DATABASE NATURAL_CYCLES;

CREATE TABLE RAW_BOOKS (
    SRC_JSON VARIANT
    );
```
Here are things I considered while uploading the 5 (NDJSON) files
- Number of load operations that run in parallel should not exceed the number of datafiles to be loaded (5 in this case)
- Snowflake documentaiton recommends to produce data files roughly 100 - 200 MB. In this case, all the files are roughly under 2 MB so this recommendation does not apply.
    - Snowflake also imposes a limit of 16 MB per row for indiviadual rows when the data type is `VARIANT`. This is not relevant for our files
- Snowflake recommends to enable `STRIP_OUTER_ARRAY` file format option for the command `COPY INTO table` to remove the outer array structure and load the records into separate table rows


Then the next step is to upload the files into the table. This consists of two steps:
1. Upload (i.e. stage) the files to a Snowflake named stage using the `PUT` command
2. Load the contents of the staged files into the Snowflake database `NATURAL_CYCLES` using the command `COPY INTO`


### Commands

```
-- Select the right database
USE NATURAL_CYCLES;

-- Select the right schema
USE SCHEMA PUBLIC; 

-- Create an Internal Named Stage
CREATE OR REPLACE STAGE my_named_stage;

-- Create a file format
CREATE OR REPLACE FILE FORMAT my_ndjson_format
TYPE = json
strip_outer_array = FALSE
;

-- Stage all .ndjson files
PUT
file:///Users/natitaw/Documents/GitHub/nytimes-books/data/*.ndjson @my_named_stag
e
PARALLEL = 5
AUTO_COMPRESS = FALSE;
```

We can now confirm that the files are staged using the following: `LIST @my_named_stage;` which returns the following 
``` bash
+-----------------------------------------------+---------+----------------------------------+------------------------------+
| name                                          |    size | md5                              | last_modified                |
|-----------------------------------------------+---------+----------------------------------+------------------------------|
| my_named_stage/audio-fiction.ndjson           | 2318272 | 19e166835be2e2d0c5e009d1aee4d9d0 | Fri, 3 Mar 2023 19:05:04 GMT |
| my_named_stage/audio-nonfiction.ndjson        | 2322464 | 82a90e280992b295ca08bde7c8686b3a | Fri, 3 Mar 2023 19:05:05 GMT |
| my_named_stage/business-books.ndjson          |  529104 | 9535d8b4bafcce7517e86e4e20ca8334 | Fri, 3 Mar 2023 19:04:58 GMT |
| my_named_stage/graphic-books-and-manga.ndjson | 1480256 | f97827f357554a682de20d60310689f0 | Fri, 3 Mar 2023 19:05:02 GMT |
| my_named_stage/mass-market-monthly.ndjson     | 1529152 | af8f3b9103635d5a52c02b19fe2fcdd2 | Fri, 3 Mar 2023 19:05:05 GMT |
+-----------------------------------------------+---------+----------------------------------+------------------------------+

```

Continuing

```SQL
COPY INTO RAW_BOOKS
FROM @~/my_named_stage
FILE_FORMAT = my_ndjson_format
PATTERN = '.*[.]ndjson'
PURGE = TRUE;
```



## Part 3: Transform


