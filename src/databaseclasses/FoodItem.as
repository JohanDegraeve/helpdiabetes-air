package databaseclasses
{
	import mx.collections.ArrayCollection;
	
	import utilities.ExcelSorting;
	
	public class FoodItem
	{
		private var _itemDescription:String;
		
		private var unitList:ArrayCollection;
		
		private var _itemid:int;
		
		/**
		 * expects an array of units<br>
		 * itemid is the id as known in the database<br>
		 * there's no database storage when creating a FoodItem<br>
		 */
		public function FoodItem(foodItemDescription:String, units:ArrayCollection,itemid:int) {
			unitList = units;
			this._itemDescription = foodItemDescription;
			this._itemid = itemid;
		}
		
		/*
		public function getItemDescription():String {
			return _itemDescription;
		}
		
		public function setItemDescription(itemDescription:String):void {
			this._itemDescription = itemDescription;
		}
		*/
		
		public function getUnit(location:int):Unit {
			return unitList.getItemAt(location) as Unit;
		}
		
		public function addUnit(newUnit:Unit):void {
			unitList.addItem(newUnit);
		}
		
		/**
		 * compares the itemdescriptions according to excel rules 
		 **/
		public function compareTo(foodItemToCompare:FoodItem):int {
			return ExcelSorting.compareStrings(this._itemDescription,foodItemToCompare._itemDescription);
		}
		

		public function getNumberOfUnits():int {
			return unitList.length;
		}

		[Bindable]
		public function get itemDescription():String
		{
			return _itemDescription;
		}

		public function set itemDescription(value:String):void
		{
			_itemDescription = value;
		}

		internal function get itemid():int
		{
			return _itemid;
		}

		internal function set itemid(value:int):void
		{
			_itemid = value;
		}
		

	}
}