package objects
{
	import mx.collections.ArrayCollection;

	public class FoodItem
	{
		private var itemDescription:String;
		
		private var unitList:ArrayCollection;
		
		public function FoodItem()
		{
			unitList = new ArrayCollection();
		}
		
		public function FoodItem(newFoodItem:FoodItem) {
			itemDescription = newFooditem.getItemDescription();
			unitList = new ArrayCollection();
			for (var i:int = 0;i < newfooditem.getNumberOfUnits(); i++) {
				unitList.addItem(new Unit(newFooditem.getUnit(i)));
			}
		}
		
		public function FoodItem(itemDescription:String, firstUnit:Unit) {
			this.itemDescription = itemDescription;
			unitList = new ArrayCollection();
			unitList.addItem(new Unit(firstUnit));
		}
		
		public function getItemDescription():String {
			return itemDescription;
		}
		
		public function setItemDescription(itemDescription:String):void {
			this.itemDescription = itemDescription;
		}
		
		public function getUnit(location:int):Unit {
			return unitList.getItemAt(location);
		}
		
		public function addUnit(newUnit:Unit):void {
			unitList.addItem(newUnit);
		}
		
		/**
		 * compares the itemdescriptions according to excel rules 
		 **/
		public function compareTo(foodItemToCompare:FoodItem):int {
			return compareItemDescriptionTo (FoodItemToCompare.itemDescription);
		}
		
		/**
		 * compares the strings according to excel rules 
		 **/
		public int compareItemDescriptionTo (String itemDescriptionToCompareString) {
			int returnvalue = 0;
			int index = 0;
			
			char[] thisItemDescription = itemDescription.toCharArray(); 
			char[] itemDescriptionToCompare = itemDescriptionToCompareString.toCharArray(); 
			
			while ((index < thisItemDescription.length) && 
				(index < itemDescriptionToCompare.length)) {
				if (ExcelCharacter.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) != 0) {
					break;
				}
				index++;	
			}
			if ((index < itemDescription.length()) && 
				(index < itemDescriptionToCompare.length)) {
				if (ExcelCharacter.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) < 0)
					return -1;
				if (ExcelCharacter.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) > 0) 
					return 1;
			}
			//for sure thisItemDescription[index] = ItemDescriptionToCompare[index]
			//now it could still be that the lengths are different, we much be checked
			if ((index >= itemDescription.length()) || 
				(index >= itemDescriptionToCompare.length)) {
				if (thisItemDescription.length < itemDescriptionToCompare.length) return -1;
				if (thisItemDescription.length > itemDescriptionToCompare.length) return  1;
			}
			return returnvalue;
		}

		public function getNumberOfUnits():int {
			retun unitList.length;
		}
		
		

	}
}