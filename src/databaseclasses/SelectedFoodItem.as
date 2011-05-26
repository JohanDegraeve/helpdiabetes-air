package databaseclasses
{

	public class SelectedFoodItem
	{
		private var _itemDescription:String;
		private var _unit:Unit;
		private var _chosenAmount:Number;

		public function SelectedFoodItem(description:String, unit:Unit,chosenAmount:Number):void
		{
			this._unit = new Unit(description,unit.;
			this._itemDescription = description;
			this._chosenAmount = chosenAmount;
		}
		
		
		public function get itemDescription():String
		{
			return _itemDescription;
		}

		public function set itemDescription(value:String):void
		{
			_itemDescription = value;
		}

		public function get unit():Unit
		{
			return _unit;
		}

		public function set unit(value:Unit):void
		{
			_unit = value;
		}

		public function get chosenAmount():Number
		{
			return _chosenAmount;
		}

		public function set chosenAmount(value:Number):void
		{
			_chosenAmount = value;
		}


	}
}