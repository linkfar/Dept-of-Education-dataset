library(readr)
library(RSQLite)
library(rpart)
library(caret)
library(randomForest)
library(e1071)
library(ggplot2)

## sc = read.csv(file="Scorecard.csv",head=TRUE,sep=",")
db <- dbConnect(dbDriver("SQLite"), "database.sqlite")
train <- dbGetQuery(db, "
/*SELECT Year, bin*binsize as CostOfAttendancePerYear, 
	-- round(AVG(gt_25k_p10), 2)
	cast(AVG(mn_earn_wne_p10) as integer) as MeanEarning10YrsAfterMatriculation
FROM(
    SELECT *, quant/binsize as bin
    FROM(	 
        SELECT *, 5000 as binsize,
	       	-- TUITFTE as quant -- net tuition revenue of school per full-time student
	       	COSTT4_A as quant -- total cost of attendance/yr for Title IV aid students
	       	-- TUITIONFEE_IN as quant -- tuition/yr, in-state
	       	-- TUITIONFEE_OUT as quant -- tuition/yr, out-of-state
		-- cast(MALE_DEBT_MDN as integer) as quant -- median debt for male students
		-- cast(FEMALE_DEBT_MDN as integer) as quant -- median debt for female students
		-- cast(DEBT_MDN as integer) as quant -- median debt for all students
	 FROM Scorecard
	 WHERE mn_earn_wne_p10 != 'PrivacySuppressed' AND mn_earn_wne_p10 IS NOT NULL
    )   
)
GROUP BY Year, bin
ORDER BY Year, bin asc*/

SELECT Year, ADM_RATE_ALL, COSTT4_A, UGDS_BLACK, PPTUG_EF, INC_PCT_LO, UG25abv, PAR_ED_PCT_1STGEN, PCTFLOAN, C150_4
	   -- CONTROL, SATVR75, SATWR75, SATMT75, TUITIONFEE_IN, TUITIONFEE_OUT, UGDS_WHITE 
FROM Scorecard
WHERE Year = 2011 	
    AND COSTT4_A != 'PrivacySuppressed' AND COSTT4_A IS NOT NULL
    AND ADM_RATE_ALL != 'PrivacySuppressed' AND ADM_RATE_ALL IS NOT NULL
    AND UGDS_BLACK != 'PrivacySuppressed' AND UGDS_BLACK IS NOT NULL
    AND PPTUG_EF != 'PrivacySuppressed' AND PPTUG_EF IS NOT NULL
    AND INC_PCT_LO != 'PrivacySuppressed' AND INC_PCT_LO IS NOT NULL
    AND UG25abv != 'PrivacySuppressed' AND UG25abv IS NOT NULL
    AND PAR_ED_PCT_1STGEN != 'PrivacySuppressed' AND PAR_ED_PCT_1STGEN IS NOT NULL
    AND PCTFLOAN != 'PrivacySuppressed' AND PCTFLOAN IS NOT NULL
    AND C150_4 != 'PrivacySuppressed' AND C150_4 IS NOT NULL
    /*AND CONTROL != 'PrivacySuppressed' AND CONTROL IS NOT NULL
    AND SATVR75 != 'PrivacySuppressed' AND SATVR75 IS NOT NULL
    AND SATWR75 != 'PrivacySuppressed' AND SATWR75 IS NOT NULL
    AND SATMT75 != 'PrivacySuppressed' AND SATMT75 IS NOT NULL
    AND TUITIONFEE_IN != 'PrivacySuppressed' AND TUITIONFEE_IN IS NOT NULL
    AND TUITIONFEE_OUT != 'PrivacySuppressed' AND TUITIONFEE_OUT IS NOT NULL
    AND UGDS_WHITE != 'PrivacySuppressed' AND UGDS_WHITE IS NOT NULL
    AND female != 'PrivacySuppressed' AND female IS NOT NULL
    AND married != 'PrivacySuppressed' AND married IS NOT NULL*/
")
# print(train)

plot(train$ADM_RATE_ALL, train$C150_4, main='Program completion rate in 4-year schools vs admission rate', xlab='Fraction of students admitted', ylab='Fraction of students completing program within 6 years')

plot(train$COSTT4_A, train$C150_4, main='Program completion rate in 4-year schools vs cost of attendance', xlab='Cost of attendance/year', ylab='Fraction of students completing program within 6 years')

plot(train$INC_PCT_LO, train$C150_4, main='Program completion rate for students from low-income families', xlab='Fraction of students from families with income <$30000/yr', ylab='Fraction of students completing program within 6 years')

plot(train$PAR_ED_PCT_1STGEN, train$C150_4, main='Program completion rate for first-generation students', xlab='Fraction of 1st-generation college students', ylab='Fraction of students completing program within 6 years')

test <- dbGetQuery(db, "
SELECT Year, ADM_RATE_ALL, COSTT4_A, UGDS_BLACK, PPTUG_EF, INC_PCT_LO, UG25abv, PAR_ED_PCT_1STGEN, PCTFLOAN, C150_4 
FROM Scorecard
WHERE Year = 2013 	
    AND COSTT4_A != 'PrivacySuppressed' AND COSTT4_A IS NOT NULL
    AND ADM_RATE_ALL != 'PrivacySuppressed' AND ADM_RATE_ALL IS NOT NULL
    AND UGDS_BLACK != 'PrivacySuppressed' AND UGDS_BLACK IS NOT NULL
    AND PPTUG_EF != 'PrivacySuppressed' AND PPTUG_EF IS NOT NULL
    AND INC_PCT_LO != 'PrivacySuppressed' AND INC_PCT_LO IS NOT NULL
    AND UG25abv != 'PrivacySuppressed' AND UG25abv IS NOT NULL
    AND PAR_ED_PCT_1STGEN != 'PrivacySuppressed' AND PAR_ED_PCT_1STGEN IS NOT NULL
    AND PCTFLOAN != 'PrivacySuppressed' AND PCTFLOAN IS NOT NULL
    AND C150_4 != 'PrivacySuppressed' AND C150_4 IS NOT NULL
")

fol = formula(C150_4 ~ ADM_RATE_ALL + COSTT4_A + UGDS_BLACK + PPTUG_EF + INC_PCT_LO + UG25abv + PAR_ED_PCT_1STGEN + PCTFLOAN)

# single decision tree
model_tree = rpart(fol, method="anova", data=train)
pred_tree = predict(model_tree, newdata=test)
accu = abs(pred_tree - test$C150_4) < 0.1
frac = sum(accu)/length(accu)
print(frac)

# random forest
model_forest = randomForest(fol, data=train)
pred_forest = predict(model_forest, newdata=test)
accu = abs(pred_forest - test$C150_4) < 0.1
frac = sum(accu)/length(accu)
print(frac)

# support vector machine
model_svm = svm(fol, data=train)
pred_svm = predict(model_svm, newdata=test)
accu = abs(pred_svm - test$C150_4) < 0.1
frac = sum(accu)/length(accu)
print(frac)

par(mfrow=c(3,1))
hist(test$C150_4, ylim=c(0,300), main='Number of colleges vs completion rate in test data', xlab='Completion rate', ylab='Number of colleges')
hist(pred_forest, xlim=c(0,1), ylim=c(0,300), breaks=10, main='Number of colleges vs completion rate predicted by random forest', xlab='Completion rate', ylab='Number of colleges')
hist(pred_svm, xlim=c(0,1), ylim=c(0,300), breaks=10, main='Number of colleges vs completion rate predicted by SVM', xlab='Completion rate', ylab='Number of colleges')


