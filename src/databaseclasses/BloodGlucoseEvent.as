package databaseclasses
{
	import mx.core.ClassFactory;
	
	import myComponents.BloodGlucoseEventItemRenderer;
	import myComponents.IListElement;
	import myComponents.TrackingViewElement;

	public class BloodGlucoseEvent extends TrackingViewElement implements IListElement
	{
		private var _timeStamp:Number;
		private var _bloodGlucoseLevel:int;
		
		/**
		 * creates a bloodglucose event and stores it immediately in the database<br>
		 * unit is a textstring denoting the unit used, mgperdl, or ... <br>
		 * if creationTimeStamp = null, then curren date and time is used
		 */
		public function BloodGlucoseEvent(glucoseLevel:int, unit:String, creationTimeStamp:Number = NaN, storeInDatabase:Boolean = true)
		{
			this._bloodGlucoseLevel = glucoseLevel;	
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			if (storeInDatabase)
				Database.getInstance().createNewBloodGlucoseEvent(glucoseLevel,_timeStamp,unit,null);
		}
		
		
		public function get bloodGlucoseLevel():int
		{
			return _bloodGlucoseLevel;
		}

		private function set bloodGlucoseLevel(value:int):void
		{
			_bloodGlucoseLevel = value;
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
			return new ClassFactory(BloodGlucoseEventItemRenderer);
		}
	}
}