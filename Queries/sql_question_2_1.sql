-- 2.1: Write a query that counts how many points each publisher has in our dataset, 
-- where points are defined as such: position 1 = 15 points, 
-- position 2 = 14 points, position 3 = 13 points, etc.
SELECT BOOK_PUBLISHER, SUM(
	-- Note: ARRAY_CONSTRUCT starts from 16 since the first element has a value of 0
    COALESCE(ARRAY_CONSTRUCT(16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)[BOOK_RANK], 0)
) AS POINTS 
FROM V_LISTS_BOOKS 
GROUP BY BOOK_PUBLISHER 
ORDER BY POINTS DESC;