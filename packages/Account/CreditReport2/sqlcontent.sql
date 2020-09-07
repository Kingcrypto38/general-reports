SELECT ACCOUNTLIST_V1.ACCOUNTNAME, ACCOUNTLIST_V1.CREDITLIMIT as CreditLimit, ACCOUNTLIST_V1.INTERESTRATE as InterestRate
    , ACCOUNTLIST_V1.INITIALBAL + total(transactions.TRANSAMOUNT) as Balance
    , ROUND( (ACCOUNTLIST_V1.CREDITLIMIT + ACCOUNTLIST_V1.INITIALBAL + total(transactions.TRANSAMOUNT)), 2) as AvailableCredit
    , C.PFX_SYMBOL AS PFX_SYMBOL, C.SFX_SYMBOL AS SFX_SYMBOL, C.GROUP_SEPARATOR AS GROUP_SEPARATOR, C.DECIMAL_POINT AS DECIMAL_POINT
    , IFNULL(CH.CURRVALUE, c.BASECONVRATE) AS CURRVALUE
FROM
	(
		SELECT
			CA1.ACCOUNTID, CA1.TRANSDATE, CA1.STATUS, 
			(case when CA1.TRANSCODE='Deposit' then CA1.TRANSAMOUNT else -CA1.TRANSAMOUNT end) as TRANSAMOUNT
		FROM
			CHECKINGACCOUNT_V1 AS CA1
		UNION ALL
		SELECT
			CA2.TOACCOUNTID as ACCOUNTID, CA2.TRANSDATE, CA2.STATUS, CA2.TOTRANSAMOUNT
		FROM
			CHECKINGACCOUNT_V1 AS CA2
		WHERE
			CA2.TRANSCODE = 'Transfer'
	) as transactions
INNER JOIN ACCOUNTLIST_V1 on ACCOUNTLIST_V1.ACCOUNTID = transactions.ACCOUNTID
INNER JOIN CURRENCYFORMATS_V1 as c on ACCOUNTLIST_V1.CURRENCYID=c.CURRENCYID
LEFT JOIN CURRENCYHISTORY_V1 AS CH ON CH.CURRENCYID = c.CURRENCYID AND 
	                     CH.CURRDATE = (
                                                    SELECT	MAX(CRHST.CURRDATE) 
                                                      FROM	CURRENCYHISTORY_V1 AS CRHST
                                                     WHERE	CRHST.CURRENCYID = c.CURRENCYID
                                                )
WHERE transactions.STATUS NOT IN ('V','D')
AND ACCOUNTLIST_V1.ACCOUNTTYPE = "Credit Card"
AND ACCOUNTLIST_V1.STATUS <> "Closed"
GROUP BY ACCOUNTLIST_V1.ACCOUNTID
ORDER BY ACCOUNTLIST_V1.INTERESTRATE DESC