public class GenerateTestClassUtil {
	
    public static boolean isCheckNullOrBlank = false;
    
    public static Map<String, Schema.DescribeFieldResult> getFieldMetaData(Schema.DescribeSObjectResult dsor) {
        
        // the map to be returned with the final data
        Map<String,Schema.DescribeFieldResult> finalMap = new Map<String, Schema.DescribeFieldResult>();
        
        // iterate over the requested fields and get the describe info for each one. 
        // add it to a map with field name as key
        
        for(Schema.SObjectField sof : dsor.fields.getMap().values()){
            Schema.DescribeFieldResult dfr = sof.getDescribe();
            finalMap.put(sof.getDescribe().getName(), dfr); 
        }
        return finalMap;
    }
    
    
    

}