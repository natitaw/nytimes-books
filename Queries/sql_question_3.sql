-- Find which books had the longest uprising trends and how long (in months) 
-- they were, where an uprising trend is defined as when a book has a greater 
-- or equal position in month X than in month X - 1

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
