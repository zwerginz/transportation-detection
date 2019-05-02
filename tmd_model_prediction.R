setwd('C:/Users/zwerg/OneDrive/School/DS 740/Final Project')

tmd <- read.csv('dataset_5secondWindow%5B3%5D.csv', 
                col.names=c('time', 'accelerometer.mean', 'accelerometer.min', 
                            'accelerometer.max', 'accelerometer.std', 
                            'game_rotation_vector.mean','game_rotation_vector.min', 
                            'game_rotation_vector.max', 'game_rotation_vector.std',
                            'gyroscope.mean', 'gyroscope.min', 'gyroscope.max',
                            'gyroscope.std', 'gyroscope_uncalibrated.mean',
                            'gyroscope_uncalibrated.min', 'gyroscope_uncalibrated.max',
                            'gyroscope_uncalibrated.std', 'linear_acceleration.mean',
                            'linear_acceleration.min', 'linear_acceleration.max', 
                            'linear_acceleration.std', 'orientation.mean', 
                            'orientation.min', 'orientation.max', 'orientation.std',
                            'rotation_vector.mean', 'rotation_vector.min', 
                            'rotation_vector.max', 'rotation_vector.std', 
                            'sound.mean', 'sound.min', 'sound.max', 'sound.std',
                            'speed.mean', 'speed.min', 'speed.max', 'speed.std', 'target'))

library('corrplot')
library('randomForest')
library('e1071')

corrplot(abs(cor(tmd[, 1:37])), method='color', diag=FALSE, type='upper')
tmd[, c('accelerometer.min', 'accelerometer.max', 
        'game_rotation_vector.min', 'game_rotation_vector.max',
        'gyroscope.min', 'gyroscope.max',
        'gyroscope_uncalibrated.min', 'gyroscope_uncalibrated.max',
        'linear_acceleration.min', 'linear_acceleration.max',
        'orientation.min', 'orientation.max',
        'rotation_vector.min', 'rotation_vector.max',
        'sound.min', 'sound.max',
        'speed.min', 'speed.max')] <- NULL

# set this for a smaller dataset to train on

#set.seed(4)
#ind <- sample(dim(tmd)[1], 1001, replace=F)
#tmd <- tmd[ind,]

##### MODEL SELECTION ######
mtrylist = 3:19

n <-  dim(tmd)[1]
tmd[, 1:19] <- scale(tmd[, 1:19])
set.seed(100)
rf <- tune(randomForest, target ~ ., data=tmd, ranges=list(mtry=mtrylist), importance=T)
svmfit <- tune(svm, target ~ ., data=tmd, kernel='radial', type='C-classification', ranges=list(cost=c(1, 10, 100, 1000, 5000), gamma=c(.001, .01, .1, .5, 1)))

##### MODEL VALIDATION ######
k <- 10
n <- dim(tmd)[1]
#define the cross-validation splits 
groups <- c(rep(1:k,floor(n/k)),1:(n%%k))  #produces list of group labels
set.seed(100)
cvgroups <- sample(groups, n)  #orders randomly, with seed (8) 

allpredictedCV <- rep(NA, n)
for (j in 1:k)  { 
  groupj <- (cvgroups == j)
  traindata = tmd[!groupj,]
  testdata = tmd[groupj,]
  rf <- tune(randomForest, target ~ ., data=traindata, ranges=list(mtry=mtrylist), importance=T)
  svmfit <- tune(svm, target ~ ., data=traindata, kernel='radial', type='C-classification', ranges=list(cost=c(1, 10, 100, 1000, 5000), gamma=c(.001, .01, .1, .5, 1)))
  if (rf$best.performance < svmfit$best.performance) {
    allpredictedCV[groupj] <- as.character(predict(rf$best.model, newdata=testdata, type='class'))
  } else {
    allpredictedCV[groupj] <-  as.character(predict(svmfit$best.model, newdata=testdata))
  }
  
}

sum(allpredictedCV != tmd$target)/n
