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