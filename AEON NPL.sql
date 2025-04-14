SELECT dbo.Debtor.batchno, dbo.Debtor.dia as aging, dbo.Client.name as NPLGroup, CAST(dbo.debtor.receivedDate AS DATE) as receivedDate, CAST(dbo.Debtor.ExpiryDate as DATE) as ExpiryDate, dbo.Debtor.account, dbo.Debtor.cardno, dbo.Debtor.name, dbo.Debtor.newic AS IC, dbo.Collector.name AS CRO, dbo.Debtor.producttype, dbo.debtor.statuscode, DATEDIFF(day, tblLastFollowup.followupdate, GETDATE()) AS CALLING_GAP, tblLastFollowup.followupdate AS LAST_FOLLOWUP,dbo.Debtor.ArrearsMonth AS Del_Month, 
                  dbo.Debtor.totalDebt AS ReferredAMT, dbo.Debtor.OtherCost AS Monthly, dbo.Debtor.minRepayment AS AmtPBAging1, dbo.Debtor.Principle, dbo.Debtor.NewInterest, dbo.Debtor.balance, COUNT(dbo.Followup.id) AS #Calls,
				  dbo.Debtor.minRepayment AS PushbackAMT,
				  CASE WHEN totalDaysFollowup.debtorid IS NOT NULL THEN totalDaysFollowup.totalDaysFollowup ELSE 0 END AS #FOLLOW_UP,
				  CASE WHEN totalFollowup.debtorid IS NOT NULL THEN totalFollowup.totalFollowup ELSE 0 END AS #Calls_Connected,
				  CASE WHEN B.id IS NOT NULL OR tblPayment.payment > 0 THEN 'CTC' ELSE 'UTC' END AS CTC_STATUS,
				  CASE WHEN dbo.debtor.totalPayment > 0 THEN dbo.debtor.TotalPayment ELSE 0 END AS TTL_PAID,
                  CASE WHEN debtor.flagClaimPaid = 1 AND debtor.ClaimPaidDt >= DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0) THEN debtor.ClaimPaidAmnt ELSE 0 END AS CP, CASE WHEN debtor.flagClaimPaid = 1 AND 
                  debtor.ClaimPaidDt >= DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0) THEN debtor.ClaimPaidDt END AS CP_DT, CASE WHEN debtor.flagPTP = 1 THEN debtor.ptpAmount ELSE 0 END AS PTP, 
                  CASE WHEN debtor.FlagPTP = 1 THEN debtor.nextpay END AS PTP_DT, CASE WHEN CAST(RIGHT(debtor.newic, 1) AS INT) % 2 = 0 THEN 'Female' ELSE 'Male' END AS gender, dbo.internalremark.remark,
				  COUNT(CASE WHEN dbo.followup.Status = 'LOD_S' then 1 END) AS LOD_STATUS_COUNT,
				  MIN(CASE WHEN dbo.followup.Status = 'LOD_S' then CAST(dbo.followup.followupdate AS DATE) END) AS FIRST_LOD_DATE
FROM     dbo.Followup WITH (nolock) INNER JOIN
                  dbo.Debtor WITH (nolock) ON dbo.Debtor.id = dbo.Followup.debtorid INNER JOIN
                  dbo.Client WITH (nolock) ON dbo.Debtor.clientId = dbo.Client.id INNER JOIN
                  dbo.Collector WITH (nolock) ON dbo.Collector.id = dbo.Debtor.collectorid LEFT OUTER JOIN

				  (SELECT DISTINCT Debtor_21.id
                       FROM      dbo.Debtor AS Debtor_21 WITH (NOLOCK) INNER JOIN
                                         dbo.Debtor_ContactNo WITH (NOLOCK) ON Debtor_21.id = dbo.Debtor_ContactNo.debtorid INNER JOIN
                                         dbo.ContactNumber WITH (NOLOCK) ON dbo.Debtor_ContactNo.contactNoId = dbo.ContactNumber.Id INNER JOIN
                                         dbo.Client WITH (NOLOCK) ON Debtor_21.clientId = dbo.Client.id
                       WHERE (Debtor_21.flagAbort = 0) AND (dbo.ContactNumber.FlagContactable = 1)) AS B ON debtor.id = B.id LEFT OUTER JOIN

					   (SELECT dbo.Payment.debtorid, dbo.Payment.payment, dbo.Payment.paymentdate
                       FROM      dbo.Payment WITH (NOLOCK) INNER JOIN
                                             (SELECT MAX(Payment_5.id) AS paymentId, Debtor_18.id AS debtorId
                                              FROM      dbo.Payment AS Payment_5 WITH (NOLOCK) INNER JOIN
                                                                dbo.Debtor AS Debtor_18 WITH (NOLOCK) ON Payment_5.debtorid = Debtor_18.id
                                              GROUP BY Debtor_18.id) AS tblPayment1 ON dbo.Payment.id = tblPayment1.paymentId) AS tblPayment ON debtor.id = tblPayment.debtorid LEFT OUTER JOIN

				  (SELECT dbo.Followup.followupdate, dbo.Followup.debtorid, dbo.Followup.telNo
                       FROM      dbo.Followup WITH (NOLOCK) INNER JOIN
                                             (SELECT MAX(Followup_5.followupdate) AS FollowupDate, Followup_5.debtorid
                                              FROM      dbo.Debtor AS Debtor_17 WITH (NOLOCK) INNER JOIN
                                                                dbo.Followup AS Followup_5 WITH (NOLOCK) ON Debtor_17.id = Followup_5.debtorid INNER JOIN
                                                                dbo.Client AS Client_17 WITH (NOLOCK) ON Debtor_17.clientId = Client_17.id INNER JOIN
											ClientReporting WITH (NOLOCK) ON debtor_17.clientid = ClientReporting.clientid
                                              WHERE   (Followup_5.callduration > 0) AND (Debtor_17.flagAbort = 0)
                                              GROUP BY Followup_5.debtorid) AS tblLastFollowup2 ON dbo.Followup.followupdate = tblLastFollowup2.FollowupDate AND dbo.Followup.debtorid = tblLastFollowup2.debtorid) AS tblLastFollowup ON 
                  debtor.id = tblLastFollowup.debtorid LEFT OUTER JOIN

				  (SELECT debtorid, COUNT(followup.id) AS totalFollowup
                                          FROM      dbo.Debtor AS Debtor WITH (NOLOCK) INNER JOIN
                                                            dbo.Followup AS Followup WITH (NOLOCK) ON Debtor.id = Followup.debtorid INNER JOIN
                                                            dbo.Client AS Client_14 WITH (NOLOCK) ON Debtor.clientId = Client_14.id INNER JOIN
											ClientReporting WITH (NOLOCK) ON debtor.clientid = ClientReporting.clientid
                                          WHERE   (Followup.callduration > 0)
                       GROUP BY debtorid) AS totalFollowup ON debtor.id = totalFollowup.debtorid LEFT OUTER JOIN

					   (SELECT debtorid, 
					  COUNT(totalDaysFollowup) AS totalDaysFollowup
                      FROM  (SELECT DISTINCT CAST(Followup_2.followupdate AS date) AS totalDaysFollowup, Followup_2.debtorid
                                          FROM      dbo.Debtor AS Debtor_15 WITH (NOLOCK) INNER JOIN
                                                            dbo.Followup AS Followup_2 WITH (NOLOCK) ON Debtor_15.id = Followup_2.debtorid INNER JOIN
                                                            dbo.Client AS Client_15 WITH (NOLOCK) ON Debtor_15.clientId = Client_15.id
                                          WHERE   (Followup_2.callduration > 0) AND (Debtor_15.flagAbort = 0)) AS tblFL
                       GROUP BY debtorid) AS totalDaysFollowup ON debtor.id = totalDaysFollowup.debtorid LEFT OUTER JOIN
					  

					   InternalRemark on debtor.latestInternalRemarkId = dbo.internalremark.id

WHERE  (dbo.Client.id IN (1618, 1619, 1625, 1645, 1646, 1647)) AND (dbo.Debtor.flagAbort = 0)
GROUP BY dbo.Debtor.name, dbo.InternalRemark.Remark, dbo.Debtor.dia, dbo.Client.name, dbo.Debtor.receivedDate, dbo.Debtor.ExpiryDate, dbo.Debtor.totalpayment, dbo.Debtor.newic, dbo.Debtor.account, dbo.Collector.name, dbo.Debtor.cardno, dbo.Debtor.ArrearsMonth, dbo.Debtor.producttype, dbo.Debtor.batchno, dbo.Debtor.flagClaimPaid, dbo.Debtor.ClaimPaidDt, 
                  dbo.Debtor.balance, dbo.Debtor.ClaimPaidAmnt, dbo.Debtor.flagPTP, dbo.Debtor.ptpAmount, dbo.Debtor.nextpay, dbo.Debtor.totalDebt, dbo.Debtor.minRepayment, dbo.Debtor.OtherCost, dbo.Debtor.Principle, dbo.Debtor.NewInterest, dbo.Debtor.memo, tblLastFollowup.followupdate, totalfollowup.totalfollowup, totalfollowup.debtorid, dbo.debtor.statuscode, B.id, tblpayment.payment, totalDaysFollowup.totalDaysFollowup, totalDaysFollowup.debtorid
