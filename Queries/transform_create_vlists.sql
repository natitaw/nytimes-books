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