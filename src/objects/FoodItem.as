package objects
{
	import mx.collections.ArrayCollection;
	
	import utilities.ExcelSorting;
	
	public class FoodItem
	{
		[Bindable]
		public var itemDescription:String;
		
		private var unitList:ArrayCollection;
		
		public var itemid:int;
		
		/**
		 * expects an array of units
		 * itemid is the id as known in the database
		 */
		public function FoodItem(foodItemDescription:String, units:ArrayCollection,itemid:int) {
			unitList = units;
			this.itemDescription = foodItemDescription;
			this.itemid = itemid;
		}
		
		public function getItemDescription():String {
			return itemDescription;
		}
		
		public function setItemDescription(itemDescription:String):void {
			this.itemDescription = itemDescription;
		}
		
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
			return ExcelSorting.compareStrings(this.itemDescription,foodItemToCompare.itemDescription);
		}
		

		public function getNumberOfUnits():int {
			return unitList.length;
		}
		

	}
}