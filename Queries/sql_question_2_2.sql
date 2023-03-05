-- Question 2.1 but for books
SELECT BOOK_TITLE, SUM(
    -- Note: ARRAY_CONSTRUCT starts from 16 since the first element has a value of 0
    COALESCE(ARRAY_CONSTRUCT(16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)[BOOK_RANK], 0))
 AS POINTS 
FROM V_LISTS_BOOKS 
GROUP BY BOOK_TITLE 
ORDER BY POINTS DESC;