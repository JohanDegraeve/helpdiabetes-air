package databaseclasses
{
	import mx.core.ClassFactory;
	
	import myComponents.IListElement;
	import myComponents.TrackingViewElement;
	
	public class MedicinEvent extends TrackingViewElement implements IListElement
	{
		private var _timeStamp:Number;
		private var _medicin:String;
		private var _amount:int;
		
		/**
		 * creates a medicin event and stores it immediately in the database if storeInDatabase = true<br>
		 * if creationTimeStamp = null, then curren date and time is used
		 */
		public function MedicinEvent(amount:int, medicin:String, creationTimeStamp:Number = NaN, storeInDatabase:Boolean = true)
		{
			this._medicin = medicin;
			this._amount = amount;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (storeInDatabase)
				Database.getInstance().createNewMedicinEvent(amount:int, medicin:String, _timeStamp,null);
		}
		
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		private function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(MedicinEventItemRenderer);
		}
	}
}