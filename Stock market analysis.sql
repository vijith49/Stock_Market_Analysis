
USE stock_market;


-- KPI 1 --

SELECT 
   Year,
   Month, 
   CONCAT(ROUND(AVG(volume) / 1000000, 2), ' M') AS avg_daily_volume
FROM stocks_data
GROUP BY Year, month
ORDER BY Year, month;

-- KPI 2 --

WITH avg_beta AS (
    SELECT 
        year,  
        month,  
        Ticker,  
        AVG(beta) AS avg_beta
    FROM stocks_data
    GROUP BY year, month, Ticker
)
SELECT 
    year,  
    month,  
    Ticker,  
    ROUND(avg_beta, 2) AS Most_volatile
FROM avg_beta
WHERE avg_beta = (
    SELECT MIN(avg_beta) 
    FROM avg_beta AS sub 
    WHERE sub.year = avg_beta.year AND sub.month = avg_beta.month
)
ORDER BY year DESC, month;

-- KPI 3 --

WITH MonthlyDividends AS (
    SELECT 
        year,  
        month,  
        Ticker,  
        SUM(dividend_amount) AS total_dividend
    FROM stocks_data
    GROUP BY year, month, Ticker
), RankedDividends AS (
    SELECT 
        year,  
        month,  
        Ticker,  
        total_dividend,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY total_dividend DESC) AS highest_rank,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY total_dividend ASC) AS lowest_rank
    FROM MonthlyDividends
)
SELECT 
    year,  
    month,  
    MAX(CASE WHEN highest_rank = 1 THEN Ticker END) AS highest_dividend_stock,
    MAX(CASE WHEN highest_rank = 1 THEN total_dividend END) AS highest_dividend,
    MAX(CASE WHEN lowest_rank = 1 THEN Ticker END) AS lowest_dividend_stock,
    MAX(CASE WHEN lowest_rank = 1 THEN total_dividend END) AS lowest_dividend
FROM RankedDividends
GROUP BY year, month
ORDER BY year DESC, month;

-- KPI 4 --

WITH MonthlyPERatios AS (
    SELECT 
        year,  
        month,  
        ticker,  
        round(AVG(pe_ratio), 2) AS avg_pe_ratio
    FROM stocks_data
    GROUP BY year, month, ticker
), RankedPERatios AS (
    SELECT 
        year,  
        month,  
        ticker,  
        avg_pe_ratio,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY avg_pe_ratio DESC) AS highest_rank,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY avg_pe_ratio ASC) AS lowest_rank
    FROM MonthlyPERatios
)
SELECT 
    r1.year,  
    r1.month,  
    r1.ticker AS highest_pe_stock,
    r1.avg_pe_ratio AS highest_pe_ratio,
    r2.ticker AS lowest_pe_stock,
    r2.avg_pe_ratio AS lowest_pe_ratio
FROM RankedPERatios r1
JOIN RankedPERatios r2 
    ON r1.year = r2.year 
    AND r1.month = r2.month
    AND r1.highest_rank = 1
    AND r2.lowest_rank = 1
ORDER BY r1.year DESC, r1.month;

-- KPI 5 --

WITH MonthlyMarketCap AS (
    SELECT 
        year,  
        month,  
        ticker,  
        concat(round(SUM(market_cap)/1000000000, 2),'B') AS highest_market_cap 
    FROM stocks_data
    GROUP BY year, month, ticker
), RankedMarketCap AS (
    SELECT 
        year,  
        month,  
        ticker,  
        highest_market_cap,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY highest_market_cap DESC) AS Highest
    FROM MonthlyMarketCap
)
SELECT 
    year,  
    month,  
    ticker AS highest_market_cap_stock,  
    highest_market_cap  
FROM RankedMarketCap
WHERE Highest = 1
ORDER BY year DESC, month;

-- KPI 6&7 --

SELECT 
    year,  
    ticker,  
    ROUND(AVG(52_week_high), 2) AS avg_high_52_week,  
    ROUND(AVG(52_week_low), 2) AS avg_low_52_week  
FROM stocks_data
GROUP BY year, ticker
ORDER BY year DESC, ticker;

-- KPI 8 --

WITH SignalRank AS (
    SELECT 
        year,  
        month,  
        ticker,  
        trade_signal,  
        COUNT(*) AS signal_count,  
        ROUND(AVG(rsi), 2) AS avg_rsi,  
        ROUND(AVG(macd), 2) AS avg_macd,  
        RANK() OVER (PARTITION BY year, month, ticker ORDER BY COUNT(*) DESC) AS signal_rank  
    FROM stocks_data  
    GROUP BY year, month, ticker, trade_signal  
)  
SELECT  
    year,  
    month,  
    ticker,  
    avg_rsi,  
    avg_macd,
    trade_signal
FROM SignalRank  
WHERE signal_rank = 1  
ORDER BY year DESC, month DESC, ticker;





