COPY INTO RAW_BOOKS
FROM @~/my_named_stage
FILE_FORMAT = my_ndjson_format
PATTERN = '.*[.]ndjson'
PURGE = TRUE;