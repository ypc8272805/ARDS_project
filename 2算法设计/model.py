# -*- coding: utf-8 -*-
from sklearn.neural_network import MLPClassifier
import random
from sklearn import preprocessing
from collections import Counter 
import numpy as np
from sklearn.metrics import confusion_matrix
from sklearn.metrics import accuracy_score
from sklearn.metrics import roc_auc_score
#将完整数据集分为训练集和测试集
def trainVStest(data):
    #对原始数据进行随机排列
    random.shuffle(data)
    #将数据分组
    train_data=data[0:int(len(data)*0.7),:]
    test_data=data[int(len(data)*0.7):,:]
    return train_data,test_data
#将训练数据按照交叉验证进行处理

    
def network(laynum,data,target):
    #laynum:是神经网络的隐含层数目，由用户指定，利用这个参数创建神经网络
    clf=MLPClassifier(hidden_layer_sizes=(laynum,),activation='tanh',solver='sgd',alpha=0.0001,learning_rate='adaptive')  
    clf.fit(data,target)
    return clf
#归一化过程
def scaler(data):
    max_abs_scaler=preprocessing.MaxAbsScaler()
    data=max_abs_scaler.fit_transform(data)
    return data
#按照标签将数组分类,传入数据，要将数据和标签分开
def getClassnum(data,target): 
    class_num=len(Counter(target))
    if class_num<3:
        label_0=np.where(target==0) 
        class_0=data[label_0[0],:]
        label_1=np.where(target==1)
        class_1=data[label_1[0],:]
        return class_0,class_1
    else:
        label_0=np.where(target==0) 
        class_0=data[label_0[0],:]
        label_1=np.where(target==1)
        class_1=data[label_1[0],:]
        label_2=np.where(target==2)
        class_2=data[label_2[0],:]
        return class_0,class_1,class_2
#结果计算
def result(y_train,y_test,train_predict,test_predict):
    #计算混淆矩阵
    #训练集混淆矩阵，并计算敏感性、特异性、准确率
    result=[]
    #confusion_m_train=confusion_matrix(y_train,train_predict)
    tn, fp, fn, tp = confusion_matrix(y_train,train_predict).ravel()
    result.append(tp/(tp+fn))#灵敏度
    result.append(tn/(tn+fp))#特异性
    result.append(tp/(tp+fp))#PPV精确性和准确率是不一样的 
    result.append(tn/(tn+fn))#NPV
    result.append(accuracy_score(y_train,train_predict))#准确率
#    result.append(roc_auc_score(y_train, train_predict))#AUC
    #测试集混淆矩阵，并计算敏感性、特异性、准确率
    test_tn, test_fp, test_fn, test_tp = confusion_matrix(y_test,test_predict).ravel()
    #confusion_m_test=confusion_matrix(y_test,test_predict)
    result.append(test_tp/(test_tp+test_fn))
    result.append(test_tn/(test_tn+test_fp))
    result.append(test_tp/(test_tp+test_fp))
    result.append(test_tn/(test_tn+test_fn))
    result.append(accuracy_score(y_test, test_predict))
    result.append(roc_auc_score(y_test, test_predict))#AUC
    return result
    