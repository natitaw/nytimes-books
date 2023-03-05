-- Write a query to find how many unique books and how many total appearances each 
-- publisher appears on our dataset, ordered by total appearances.
SELECT
	BOOK_PUBLISHER, 
    COUNT(DISTINCT (BOOK_TITLE)) AS UNIQUE_BOOKS,
    COUNT(BOOK_PUBLISHER) AS TOTAL_APPERANCES
FROM V_LISTS_BOOKS 
GROUP BY BOOK_PUBLISHER
ORDER BY TOTAL_APPERANCES DESC