# Dept-of-Education-dataset
Work done on a dataset on US colleges available on Kaggle, using SQL and R: https://www.kaggle.com/c/us-dept-of-education-college-scorecard


Goal: predict the fraction of students in 4-year colleges who complete the program in less than 6 years.

I use multivariate analysis (MVA), which also goes by the name of machine learning these days. I want to predict a fraction, so this is a regression problem. I use college and aggregated student data from 2011 to train 3 different MVA methods:

  - single decision tree
  - random forest of decision trees
  - support vector machine (SVM)

The learning is subsequently evaluated on 2013 and 2009 data. Below are details of the workflow.

    The variable that I want to predict (variable of interest VOI) is C150_4 in the DB. In the first step, I look at all quantitative variables associated with colleges and (aggregated) students. 14 variables look promising in terms of predictive power:
        rate of admission for all demographics (ADM_RATE_ALL in the DB)
        total cost of attendance per year (COSTT4_A)
        fraction of students that are white (UGDS_WHITE)
        fraction of students that are black (UGDS_BLACK)
        fraction of part-time students (PPTUG_EF)
        fraction of students from low-income families, defined as annual family income < $30,000 (INC_PCT_LO)
        fraction of students above 25 years of age (UG25abv)
        fraction of first-generation college goers in the family (PAR_ED_PCT_1STGEN)
        fraction of students on federal loan (PCTFLOAN)
        75% percentile score on SAT reading (SATVR75)
        75% percentile score on SAT writing (SATWR75)
        75% percentile score on SAT math (SATMT75)
        tuition fee per year for in-state students (TUITIONFEE_IN)
        tuition fee per year for out-of-state students (TUITIONFEE_OUT)

  - I collect these variables in an R data frame and examine them for availability, integrity and correlations. The SAT scores are privacy-suppressed for the majority of cases, yielding <500 records in 2011. So I decide to leave them out. Tuition fee per year for both in-state and out-of-state students is highly correlated with the total cost of attendance per year, as expected (correlation coefficients > 90%), so the tuition fee variables are excluded. Finally, the fraction of white students has a very small correlation with the VOI, so that this is excluded as well. That leaves me with 8 training variables and 1143 events to train with.

  - I examine the correlations of these variables with the VOI, and among themselves as necessary. The correlations look like:

        Variable --------------- Correlation coefficient with VOI

        ADM_RATE_ALL------------ 0.22
        COSTT4_A --------------- 0.57
        UGDS_BLACK ------------ -0.35
        PPTUG_EF -------------- -0.40
        INC_PCT_LO ------------ -0.64
        UG25abv --------------- -0.47
        PAR_ED_PCT_1STGEN------ -0.65 (has a 74% correlation with INC_PCT_LO)
        PCTFLOAN -------------  -0.18

  - First, I train a single decision tree using the 'rpart' library with default training parameters. The most discriminating variables are seen to be:
        fraction of students from low-income families (INC_PCT_LO)
        total cost of attendance per year (COSTT4_A)
        fraction of first-generation college goers in the family (PAR_ED_PCT_1STGEN)
        rate of admission (ADM_RATE_ALL)

  - I evaluate the performance on the 2013 data. I define a correct prediction as the predicted completion rate for a given college being within 10% of the actual rate in 2013. The performance of a single tree is not very good: 64% of predictions are correct.

  - I then train a random forest of trees, again using default parameters. The four highest ranked variables, using the importance() function, are:
  
        fraction of students from low-income families (INC_PCT_LO)
        fraction of first-generation college goers in the family (PAR_ED_PCT_1STGEN)
        total cost of attendance per year (COSTT4_A)
        fraction of students above 25 years of age (UG25abv)

    The performance is better: 76% of predictions are correct.

  - Finally, I train an SVM using the 'e1071' library using default parameter values. The performance is comparable with that of the random forest: 74% of predictions are correct. But a tuning of parameters would yield better results with this method.

  - I look at the number of colleges as a function of the completion rate, from the test data, from the random forest prediction and from the SVM prediction. Both methods turn out to perform badly for large values of the completion rate. The next step in the analysis would be to look at distributions of the training variables separately for low and high completion rates, and try to understand why the training is poorer in the latter case.

  - The data are not very reliable owing to the large number of privacy suppressions. To get an idea of the spread of the data (statistical and systematic components convolved), I ran the test on 2009 data. The fraction of correct predictions are thus:
        random forest: 65%
        SVM: 69%

    which are within ~10% of the 2013 numbers.

  - The important conclusions of this study are not the performance of the MVAs, but the factors that they show to affect program completion rates the most. In general, they agree with our naive expectations as to why someone may fail to complete a college program.
