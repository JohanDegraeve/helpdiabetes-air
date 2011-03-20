<<<<<<< .mine
package databaseclasses
{
	import flash.events.Event;
	
	public class DatabaseEvent extends Event
	{
		
		public static const RESULT_EVENT:String = "ResultEvent";
		public static const ERROR_EVENT:String = "ErrorEvent";
		
		
		public var data:*;
		public var lastInsertRowID:Number;
		
		public function DatabaseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type);
		}
		
	}
}=======
package databaseclasses
{
	import flash.events.Event;
	
	public class DatabaseEvent extends Event
	{
		
		public static const DATABASE_INITIALIZED_RESULT_EVENT:String = "databaseInitializedResult";
		public static const DATABASE_INITIALIZED_ERROR_EVENT:String = "databaseInitializedError";
		
		
		public var data:*;
		public var lastInsertRowID:Number;
		
		public function DatabaseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type);
		}
		
	}
}>>>>>>> .r19
