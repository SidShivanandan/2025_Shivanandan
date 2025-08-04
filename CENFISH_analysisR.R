combofolders_enterTextdata = function(folderURL){
  library(data.table)
  library(dplyr)
  library(tidyverse)
  library(readr)
  library(utils)
  csv_names <- list.files(path = folderURL, 
                          # set the path to your folder with csv files
                          pattern = "*.csv", 
                          # select all csv files in the folder
                          full.names = T) 
  # output full file names (with path)
  csv_names2 <- data.frame(filename = csv_names, 
                           id = as.character(1:length(csv_names))) # id for joining
  
  Comboframe <- csv_names %>% 
    lapply(read_csv) %>% # read all the files at once
    bind_rows(.id = "id") %>% # bind all tables into one object, and give id for each
    left_join(csv_names2)
  
  return(Comboframe)
  
}

#Done
#combofolders_enterTextdata takes the path of the folder you enter as as a string (i.e.) in quotations ("") and also set the name of the name for the final dataframe. 

cleanup_specific_cenHapvariation_FISH = function(dirtyframe){
  
  library(dplyr)
  library(tidyverse)
  library(readr)
  library(tidyr)
  
  dirtyframe = dirtyframe[,c(3,4,11,12)]
  dirtyframe_a = separate(data = dirtyframe, col = filename, into = c("yuck", "imageID"), sep = "\\//") %>% select(-ends_with("yuck"))
  
  dirtyframe_b = separate(data = dirtyframe_a, col = Label, into = c("yuck", "roiID"), sep = "\\:") %>% select(-ends_with("yuck"))
  
  cleanframe = separate(data = dirtyframe_b, col = imageID, into = c("imageID", "2yucky", "3yucky"), sep ="\\.") %>% select(-ends_with("yucky"))
  
  #I need a unique ROI ID and Image ID combo so I need to bring those two together
  cleanframe$fociID <- paste(cleanframe$imageID, cleanframe$roiID, sep="_") #(Removed for metaphase analysis CHANGE WHEN NEEDED)
  uniqueROIs = unique(cleanframe$fociID) #make it fociID if you run the above line (74)
  pairedData = data.frame()          
  for(i in 1:length(uniqueROIs))
  {  
    temp = cleanframe %>% filter(fociID == uniqueROIs[i]) #change to fociID if line74 ran
    #temp$fociCounts = 2 #run it this way for the bad macro. make this hidden otherwise
    temp$fociCounts = length(temp$fociID) #change to fociID if line74 ran
    pairedData = rbind(pairedData, temp) #ADD[c(1,2),] if you are using the bad poor macro which duplicates or triplicates when analysing
  }
  
  
  pairedData_onlyPairs = pairedData %>% filter(pairedData$fociCounts == 2)
  #This is the new main dataset
  #With this we confirm we only have pairs of data points
  #Now we want to normalize the smaller area / RID to the larger area or RID
  
  uniqueROIs = unique(pairedData_onlyPairs$fociID) #change to fociID if line74 ran
  normalizedData_Area = data.frame()    
  normalizedData_RID = data.frame() 
  tosave_normalizedData_Area = data.frame()    
  tosave_normalizedData_RID = data.frame() 
  pairedData_onlyPairs_BD = data.frame()
  temp_RID_norm = data.frame(matrix(ncol = 2, nrow = 1))
  temp_Area_norm = data.frame(matrix(ncol = 2, nrow = 1))
  
  for(i in 1:length(uniqueROIs))
  {  
    temp = pairedData_onlyPairs %>% filter(fociID == uniqueROIs[i]) #change to fociID if line74 ran
    Bright_Dim = c("Dim", "Bright") 
    temp_RID = temp %>% arrange(RawIntDen)
    temp_RID$Bright_Dim = c("Dim", "Bright")
    pairedData_onlyPairs_BD = rbind(pairedData_onlyPairs_BD, temp_RID)
    
    temp_RID_norm$Normalized_RawIntDensity = temp_RID$RawIntDen[1]/temp_RID$RawIntDen[2]
    temp_RID_norm$Difference = temp_RID$RawIntDen[2] - temp_RID$RawIntDen[1]
    temp_RID_norm$roiIDPair = uniqueROIs[i]
    normalizedData_RID =rbind(normalizedData_RID, temp_RID_norm)
    tosave_normalizedData_RID = rbind(tosave_normalizedData_RID, temp_RID)
    
    temp_Area = temp %>% arrange(Area)
    temp_Area_norm$Normalized_Area = temp_Area$Area[1]/temp_Area$Area[2]
    temp_Area_norm$roiIDPair = uniqueROIs[i]
    normalizedData_Area =rbind(normalizedData_Area, temp_Area_norm)
    tosave_normalizedData_Area = rbind(tosave_normalizedData_Area, temp_Area)
  }
  normalizedData_RID = normalizedData_RID[,c(3,4,5)]
  normalizedData_Area = normalizedData_Area[,c(3,4)]
  
  return(list(normalizedData_RID, normalizedData_Area, tosave_normalizedData_RID, tosave_normalizedData_Area))
}

#Done
#cleanup_specific_cenHapvariation_FISH takes the dirty dataframe from the combo function and sets it up as a clean data frame that gets saved in the path of the folder you enter as as a string (i.e.) in quotations (""). The output here is a list with the normalized raw integrated density and normalized area.At the end don't forget to add three columns with the CEN number, the cell line information and replicate number.


give.n <- function(x){
  return(c(y = -0.1, label = length(x))) 
  # experiment with the multiplier to find the perfect position
}


#Done
#give.n adds the number of data points to your ggplot when you plot it out. 
#eg:stat_summary(fun.data = give.n)

#Example
#eg_cen18 = combofolders_enterTextdata("URL")
#eg_cen18_clean = cleanup_specific_cenHapvariation_FISH(eg_cen18)
