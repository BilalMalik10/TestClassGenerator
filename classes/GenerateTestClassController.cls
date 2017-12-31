global class GenerateTestClassController{
    
    public String testClassStr{get;set;}
    public String recordID {get;set;}
    public Map<Id,String> rIdVsInstanceNameMap;
    public Map<Id,Sobject> sobjectMap;
    public string ObjeLevelStr ;
    public Map<String,String> instVsTestClassStr;
    public list<String> ordeInstance ;
    public String fieldToIgnore = 'LastLoginDate,LastPasswordChangeDate,LastReferencedDate,LastViewedDate,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,SystemModstamp,FullPhotoUrl,SmallPhotoUrl,MediumPhotoUrl,BannerPhotoUrl,SmallBannerPhotoUrl,MediumBannerPhotoUrl';
    public set<String> addressFields;
    public integer counter = 0;
    public boolean isCheckNullOrBlank {get;set;}
    public boolean isCheckReferenceObjects {get;set;}
    
    public GenerateTestClassController(){
        testClassStr = '';
        recordID = '';
        ObjeLevelStr='';
        isCheckNullOrBlank = true;
        isCheckReferenceObjects = true;
        addressFields = new set<string>{'City','Country','CountryCode','Latitude','Longitude','PostalCode','State','StateCode','Street'};
    }
    
    public void init(){
        try{  
            ordeInstance = new list<String>();
            rIdVsInstanceNameMap=new Map<Id,String>();
            instVsTestClassStr=new Map<String,String>();
            sobjectMap = new Map<Id,Sobject>();
            counter = 0;
            system.debug('Initn');
            
        } catch(Exception e ){
            system.debug('e.messgae ' + e.getStackTraceString());
            system.debug('e.cause ' + e.getCause());
            system.debug('e.line ' + e.getMessage());
        }
        
        //return null;
    }
    
    public pageReference doGeneateTestData(){
        if(!String.isBlank(recordID)){
            init();
            Map<String,Schema.DescribeSObjectResult> sObjectResult = new Map<String,Schema.DescribeSObjectResult>();
            Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();
            
            for(String s:describe.keyset()){
                sObjectResult.put(s,describe.get(s).getDescribe());
            }
            doProcess(recordID,sObjectResult);
            system.debug('instVsTestClassStr ' + instVsTestClassStr);
            String finalString = '';
            for(integer i=ordeInstance.size()-1; i>=0;  i--){
                if(instVsTestClassStr.containskey(ordeInstance[i])){
                    finalString += instVsTestClassStr.get(ordeInstance[i]);
                }
            }
            testClassStr = finalString ;
        }
        
        return null;
    }
    
    public void doProcess(String sId,Map<String,Schema.DescribeSObjectResult> sObjectResult){
        counter++;
        String currentSobjectTestString = ''; //
        
        //Get Sobject Type. 
        Id Ids = (ID)sId;
        String sobjectType = Ids.getSObjectType().getDescribe().getName();
        
        system.debug('sId ' + sId + ' Ids =  '+ Ids + ' sobjectType ' + sobjectType);
        
        //GetSObject PRoperty
        
        if(sObjectResult.containsKey(sobjectType.toLowerCase())){
            Schema.DescribeSObjectResult dsobjRslt = sObjectResult.get(sobjectType.toLowerCase());
            
            system.debug('sobjectType ' + sobjectType.toLowerCase());
            system.debug('dsobjRslt  ' + dsobjRslt );
            system.debug('dsobjRslt.isAccessible  ' + dsobjRslt.isAccessible() );
            system.debug('dsobjRslt.isCreateable  ' + dsobjRslt.isCreateable() );
            system.debug('dsobjRslt.isQueryable' + dsobjRslt.isQueryable() );
            
            //Check Accessibility
            if(dsobjRslt.isAccessible() && dsobjRslt.isCreateable() && dsobjRslt.isQueryable()){
                
                String sObjNAme = dsobjRslt.getLocalName();
                
                //Get field Results for this sObject.
                Map<String,Schema.DescribeFieldResult> dsfrMap = GenerateTestClassUtil.getFieldMetaData(dsobjRslt);
                
                //We are to Prepare data for current SObject.
                String soInstanceName = sObjNAme+'SO'+counter;
                currentSobjectTestString = sObjNAme + ' ' +  soInstanceName + ' = new ' +  sObjNAme + '();' + '\n';
                ordeInstance.add(soInstanceName );
                instVsTestClassStr.put(soInstanceName,currentSobjectTestString);
                
                // map of all fields in the object
                Map<String, Schema.SObjectField> objectFields = dsobjRslt.fields.getMap();
                
                // Get all of the fields on the object
                Set<String> fieldNames = objectFields.keySet();     
                List<String> fieldNameList = new List<String>();
                fieldNameList.addAll(fieldNames);
                
                // Build a Dynamic Query String.
                String soqlQuery = ' SELECT ' + string.join (fieldNameList, ',') + ' FROM ' + sObjNAme + ' Where Id =: Ids';
                system.debug('sObjNAme ' + sObjNAme + ' Ids =  '+ Ids + ' soqlQuery ' + soqlQuery);
                
                // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
                sObject record = Database.query(soqlQuery);
                
                sobjectMap.put(Ids,record);
                
                for(String fieldName : dsfrMap.keySet() ){  
                    
                    Schema.DisplayType fielddataType = dsfrMap.get(fieldName).getType();
                    
                    //Continue if Field is not accessible.
                    if(!dsfrMap.get(fieldName).isAccessible() ) continue;
                    
                    //continue of field is calculated / formula
                    if(dsfrMap.get(fieldName).isCalculated() ) continue;
                    
                    //If field name is Id then its record id so, add into map and move to next field.
                    if(fieldName.equalsIgnoreCase('Id')){
                        rIdVsInstanceNameMap.put((Id)record.get(fieldName),soInstanceName); 
                        continue;
                    }
                    
                    //Continue if field is to be ignored.
                    if(fieldToIgnore.containsIgnoreCase(fieldName)) continue;
                    
                    //Check for Reference type of field.
                    if(fielddataType==Schema.DisplayType.REFERENCE){
                        if((string)record.get(fieldName)!=null) {
                            
                            //Check Record Type ID Logic.
                            if(fieldName.containsIgnoreCase('RecordTypeId')){
                                //String rtName  = dsobjRslt.getRecordTypeInfosById().get((Id)record.get(fieldName)).getName(); //Map<Id,Schema.RecordTypeInfo> rtMapById
                                //Id rtID = dsobjRslt.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
								//currentSobjectTestString = instVsTestClassStr.containskey(soInstanceName) ? instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+ '\'' +rtID + '\'' + '; \n' : soInstanceName+'.'+fieldName+'='+ '\'' +rtID +'\''+'; \n';
                                
                                //Logic to Get Record Type Id. 
                                String rcTypeString = '';
                                rcTypeString+= 'Map<String,Schema.SobjectType> gd = Schema.getGlobalDescribe();' + '\n';
                                
                                //Retrieve the describe result for the desired object
                                rcTypeString+= 'Schema.DescribeSObjectResult dsobjRslt = gd.get(' + '\''+sObjNAme+'\''+ ').getDescribe();' + '\n';
                                
                                rcTypeString+= 'String rtName'+soInstanceName+' = '+ '\'' + dsobjRslt.getRecordTypeInfosById().get((Id)record.get(fieldName)).getName() + '\';' + '\n';
                                rcTypeString+= 'Id rtID'+soInstanceName+'= dsobjRslt.getRecordTypeInfosByName().get(rtName'+soInstanceName+').getRecordTypeId();'+'\n';
								
                                currentSobjectTestString = instVsTestClassStr.containskey(soInstanceName) ? instVsTestClassStr.get(soInstanceName) + rcTypeString + soInstanceName+'.'+fieldName+'= rtID'+soInstanceName+';'+'\n' : rcTypeString + soInstanceName+'.'+fieldName+'= rtID'+soInstanceName+';'+'\n';
                                
                            }
                            //Other than Record Type. 
                            else if(!sobjectMap.containsKey((ID)record.get(fieldName))){                      
                                //testClassStr += 'Check RelationField ' + fieldName + ' Relation ship = ' +(ID)record.get(fieldName) + ' '+ dsfrMap.get(fieldName).getType() + ' ' + dsfrMap.get(fieldName).getRelationshipOrder() + '\n';
                                instVsTestClassStr.put(soInstanceName,currentSobjectTestString);
                                
                                //Check IF User has selected option to look for reference Objects?
                                if(isCheckReferenceObjects){
                                    doProcess((string)record.get(fieldName), sObjectResult);
                                    if(rIdVsInstanceNameMap.containsKey((Id)record.get(fieldName))){
                                		currentSobjectTestString = instVsTestClassStr.containskey(soInstanceName) ? instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+rIdVsInstanceNameMap.get((Id)record.get(fieldName))+'.Id'+'; \n' : soInstanceName+'.'+fieldName+'='+rIdVsInstanceNameMap.get((Id)record.get(fieldName))+'.Id'+'; \n';                            
                                	}
                                }else {
                                    currentSobjectTestString = instVsTestClassStr.containskey(soInstanceName) ? instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+'\''+(Id)record.get(fieldName)+'\''+'; \n' : soInstanceName+'.'+fieldName+'='+'\''+(Id)record.get(fieldName)+'\''+'; \n';
                            
                                }
                            }
                            
                            instVsTestClassStr.put(soInstanceName,currentSobjectTestString);
                        }
                    }
                    
                    //Logic of creating Field Values. 
                    if(fielddataType!=Schema.DisplayType.ADDRESS && dsfrMap.get(fieldName).isUpdateable()){                        
                        
                        //Check if field Type is String? 
                        if(fielddataType==Schema.DisplayType.String || fielddataType==Schema.DisplayType.TEXTAREA || fielddataType==Schema.DisplayType.URL || fielddataType==Schema.DisplayType.EMAIL || fielddataType==Schema.DisplayType.MultiPicklist || fielddataType==Schema.DisplayType.Picklist || fielddataType==Schema.DisplayType.Phone ){
                            if((isCheckNullOrBlank && record.get(fieldName)!=null) || (!isCheckNullOrBlank)) {                                
                                if(instVsTestClassStr.containskey(soInstanceName) ){
                                    if(record.get(fieldName)!=null){
                                        currentSobjectTestString = instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+'\''+((String)record.get(fieldName)).escapeJava()+'\''+'; \n';
                                    } else {
                                        currentSobjectTestString = instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n';
                                    }
                                } else {
                                    if(record.get(fieldName)!=null){
                                        currentSobjectTestString = soInstanceName+'.'+fieldName+'='+'\''+((String)record.get(fieldName)).escapeJava()+'\''+'; \n';
                                    } else {
                                        currentSobjectTestString = soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n';
                                    }
                                }
                            }
                        }
                        //Check if field Type is boolean,number,
                        else if(fielddataType==Schema.DisplayType.boolean || fielddataType==Schema.DisplayType.Integer || fielddataType==Schema.DisplayType.DOUBLE || fielddataType==Schema.DisplayType.Currency || fielddataType==Schema.DisplayType.Percent  ){
                            if((isCheckNullOrBlank && record.get(fieldName)!=null) || (!isCheckNullOrBlank))
                            currentSobjectTestString = instVsTestClassStr.containskey(soInstanceName) ? instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n' : soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n';
                        }
                        //Check if Date? 
                        else if(fielddataType==Schema.DisplayType.DATE ){
                            if((isCheckNullOrBlank && record.get(fieldName)!=null) || (!isCheckNullOrBlank)){                                
                                if(instVsTestClassStr.containskey(soInstanceName) ){
                                    if(record.get(fieldName)!=null){
                                        currentSobjectTestString = instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+'Date.valueOf('+'\''+record.get(fieldName)+'\''+')'+'; \n';
                                    } else {
                                        currentSobjectTestString = instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n';
                                    }
                                } else {
                                    if(record.get(fieldName)!=null){
                                        currentSobjectTestString = soInstanceName+'.'+fieldName+'='+'Date.valueOf('+'\''+record.get(fieldName)+'\''+')'+'; \n';
                                    } else {
                                        currentSobjectTestString = soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n';
                                    }
                                }
                            }
                        }
                        //Check if Date Time?
                        else if(fielddataType==Schema.DisplayType.DATETIME){
                            if((isCheckNullOrBlank && record.get(fieldName)!=null) || (!isCheckNullOrBlank)){                                
                                if(instVsTestClassStr.containskey(soInstanceName) ){
                                    if(record.get(fieldName)!=null){
                                        currentSobjectTestString = instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+'DateTime.valueOf('+'\''+record.get(fieldName)+'\''+')'+'; \n';
                                    } else {
                                        currentSobjectTestString = instVsTestClassStr.get(soInstanceName) + soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n';
                                    }
                                } else {
                                    if(record.get(fieldName)!=null){
                                        currentSobjectTestString = soInstanceName+'.'+fieldName+'='+'DateTime.valueOf('+'\''+record.get(fieldName)+'\''+')'+'; \n';
                                    } else {
                                        currentSobjectTestString = soInstanceName+'.'+fieldName+'='+record.get(fieldName)+'; \n';
                                    }
                                }
                            }
                        }
                        instVsTestClassStr.put(soInstanceName,currentSobjectTestString); 
                    }
                }
                
                currentSobjectTestString = instVsTestClassStr.containskey(soInstanceName) ? instVsTestClassStr.get(soInstanceName) + 'insert ' + soInstanceName +';\n' : 'insert ' + soInstanceName +';\n';
                instVsTestClassStr.put(soInstanceName,currentSobjectTestString);
                
            }
        }
    }
    
}
