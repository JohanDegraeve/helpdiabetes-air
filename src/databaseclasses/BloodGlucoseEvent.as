package databaseclasses
{
	public class BloodGlucoseEvent
	{
		private var _creationTimeStamp:Number;
		private var _bloodGlucoseLevel:int;
		
		public function BloodGlucoseEvent()
		{
			
		}
		
		
		public function get bloodGlucoseLevel():int
		{
			return _bloodGlucoseLevel;
		}

		private function set bloodGlucoseLevel(value:int):void
		{
			_bloodGlucoseLevel = value;
		}

		public function get creationTimeStamp():Number
		{
			return _creationTimeStamp;
		}

		private function set creationTimeStamp(value:Number):void
		{
			_creationTimeStamp = value;
		}

	}
}