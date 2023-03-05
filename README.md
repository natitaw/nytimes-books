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
 2.  Writing a script that accepts the path to the JSON file from the first task, as well as an optional end date, and retrieves the books in each list for the specified date range. The output is a single NDJson file per list containing the entire API response for all months in that list.
    
 This project can be useful for anyone who wants to work with the NYTimes Books API to retrieve data on books and book-related content from The New York Times. The code and documentation on the GitHub page can serve as a helpful starting point for anyone looking to build similar projects or integrate the NYTimes Books API into their own applications.


## Part 1: Extract

Here is how you can install and run the file

1. Get a free API Key at the [NYTimes Dev Portal](https://developer.nytimes.com/get-started)
    - *Note: since this is a private repo, I have already done this step so you can skip it*
2. Clone the repo
   ```sh
   git clone https://github.com/natitaw/nytimes-books.git
   ```
3. Install pip packages
   ```sh
   pip install -r requirements.txt
   ```
4. Enter your API in `config.py`
    -	*Note: since this is a private repo, I have already done step (4) so you can skip it*
   ```python
   API_KEY = 'ENTER_YOUR_API'
   ```
5. Execute `extract.py`
    ```bash
    python3 extract.py
    ```

**- This task is automated using GitHub Actions. The YAML file can be found in the 'Actions' tab or by clicking [here](https://github.com/natitaw/nytimes-books/blob/main/.github/workflows/nightly-update.yml)**
- Note: The workflow is currently manually disabled (to save my credits)

---

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

Now that the data is loaded onto Snowflake. We can do the next tasks.
- **Note: I have saved all the SQL commands in the folder [Queries](https://github.com/natitaw/nytimes-books/tree/main/Queries), but I have also presented them here for simplicity.**

### 1. Create a VIEW called `V_LISTS`

This view is created using the following command:
```SQL
CREATE OR REPLACE VIEW V_LISTS (LIST_NAME, LIST_NAME_ENCODED, BESTSELLERS_DATE, BOOKS) AS (
WITH book_table AS (
SELECT PARSE_JSON(PARSE_JSON(SRC_JSON):results) AS src FROM RAW_BOOKS)

SELECT 
src:list_name::STRING,
src:list_name_encoded::STRING,
src:bestsellers_date::DATE,
src:books::VARIANT

FROM book_table 
)
```

### 2. Create a VIEW called `V_LISTS_BOOKS`

This view is created using the following command:
```SQL
CREATE OR REPLACE VIEW V_LISTS_BOOKS (BOOK_TITLE, BOOK_RANK, BOOK_PUBLISHER, LIST_NAME, BESTSELLERS_DATE) AS (
SELECT 
 	F.value:title::STRING AS BOOK_TITLE,
    F.value:rank::INT AS BOOK_RANK,
    F.value:publisher::STRING AS BOOK_PUBLISHER,
    LIST_NAME::STRING,
	BESTSELLERS_DATE::DATE
 FROM V_LISTS ,
 Table(Flatten(V_LISTS.books)) F
)

```


## SQL Questions

The SQL queries for this part are shown here, but they are also committed to the repository as files.

### SQL Question 1:
Write a query to find how many unique books and how many total appearances each publisher appears on our dataset, ordered by total appearances.

```SQL
SELECT
	BOOK_PUBLISHER, 
    COUNT(DISTINCT (BOOK_TITLE)) AS UNIQUE_BOOKS,
    COUNT(BOOK_PUBLISHER) AS TOTAL_APPERANCES
FROM V_LISTS_BOOKS 
GROUP BY BOOK_PUBLISHER
ORDER BY TOTAL_APPERANCES DESC
```

### SQL Question 2:

2.1: Write a query that counts how many points each publisher has in our dataset, where points are defined as such: position 1 = 15 points, position 2 = 14 points, position 3 = 13 points, etc. 
```SQL
SELECT BOOK_PUBLISHER, SUM(
	-- Note: ARRAY_CONSTRUCT starts from 16 since the first element has a value of 0
    COALESCE(ARRAY_CONSTRUCT(16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)[BOOK_RANK], 0)
) AS POINTS 
FROM V_LISTS_BOOKS 
GROUP BY BOOK_PUBLISHER 
ORDER BY POINTS DESC;

```

2.2: Do the same for books
```SQL
SELECT BOOK_TITLE, SUM(
    -- Note: ARRAY_CONSTRUCT starts from 16 since the first element has a value of 0
    COALESCE(ARRAY_CONSTRUCT(16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)[BOOK_RANK], 0))
 AS POINTS 
FROM V_LISTS_BOOKS 
GROUP BY BOOK_TITLE 
ORDER BY POINTS DESC;
```

> Note: I chose to use `ARRAY_CONSTRUCT()` for question 2.1 and 2.2 despite it being slightly more complicated  because it is easier to maintain.

### SQL Question 3:
Find which books had the longest uprising trends and how long (in months) they were, where an uprising trend is defined as when a book has a greater or equal position in month X than in month X - 1

```SQL
WITH trend_table AS (
	-- 1. Create a table where the best seller dates are ordered cronologically	
    SELECT 
        BOOK_TITLE, 
        BOOK_RANK, 
        BESTSELLERS_DATE, 
        ROW_NUMBER() OVER (PARTITION BY BOOK_TITLE	ORDER BY BESTSELLERS_DATE) row_num
    FROM 
        V_LISTS_BOOKS),
	data_table AS (
    -- 2. Create a table to filter books where the best seller dates appeare within one month after the previous one
    SELECT 
    	t1.BOOK_TITLE, 
        t1.BESTSELLERS_DATE, 
        t1.BOOK_RANK, 
        t2.BOOK_RANK PREVIOUS_RANK,
        DATEDIFF(month, LAG(t1.BESTSELLERS_DATE, 1) 
        	OVER (PARTITION BY t1.BOOK_TITLE ORDER BY t1.BESTSELLERS_DATE), t1.BESTSELLERS_DATE) as month_diff    
        FROM trend_table t1
        	LEFT JOIN trend_table t2 
            	ON (t1.row_num - 1 = t2.row_num)
                AND (t1.BOOK_TITLE = t2.BOOK_TITLE)
    ),
    final_table AS(
    -- 2. Create a table that filters books appearing within one month after each other 
    	-- and with rank getting better or staying the same
        SELECT
        	BOOK_TITLE, 
            BESTSELLERS_DATE,
            CASE
            	WHEN trend_length IS NULL THEN 1
                ELSE trend_length END
            AS trend_length
        FROM (SELECT 
        	*,
            DATEDIFF(month, LAG(BESTSELLERS_DATE, 1) 
            	OVER (PARTITION BY BOOK_TITLE ORDER BY BESTSELLERS_DATE), 
                		BESTSELLERS_DATE) as trend_length 
        FROM data_table
        WHERE month_diff <= 1 
        AND BOOK_RANK <= PREVIOUS_RANK)
    )

-- 3. Count consequetive 1's to determine the longest trends
SELECT 	
    BOOK_TITLE,
    TREND_LENGTH,
    MIN(BESTSELLERS_DATE) as TREND_START,
    COUNT(TREND_LENGTH) as TREND
FROM final_table 
WHERE TREND_LENGTH = 1
GROUP BY 1,2
ORDER by 4 DESC

```

The books with the longest uprising trends (and how long) were:
1. Thinking Fast and Slow (7 Months)
2. Outliers (7 Months)
3. The Power of Habit (6 Months) 

## Snowflake Dashboards

### Histogram of Total Apperances of Book Publishers

![Histogram of Total Apperances of Book Publishers](hist_plot.png?raw=true)



End of file