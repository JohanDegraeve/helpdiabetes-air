/**
 * implements IList
 * to add one int value that is actually the fooditemid as stored in the database
 * Actually all the methods from IList should not be used by the application
 * 
 * this is something that should be changed
 */
package objects
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.collections.Sort;
	import mx.effects.IAbstractEffect;
	import mx.events.CollectionEvent;
	
	public class FoodTableList implements IList
	{
		private var itemidlist:ArrayCollection;
		private var foodtable:ArrayCollection;
		
		
		public function FoodTableList()
		{
			itemidlist = new ArrayCollection();
			foodtable = new ArrayCollection();
		}
		
		public function addItemDescriptionAndItem(itemdescription:String,itemid:int):void {
			itemidlist.addItem(itemid);
			foodtable.addItem(itemdescription);
		}
		
		public function getFoodItemDescriptionAt(id:int):Object {
			return foodtable.getItemAt(id);
		}
		
		public function getFoodItemId(index:int):int {
			return itemidlist.getItemAt(index) as int;
		}
		
		public function addItemAt(item:Object, index:int):void
		{
			foodtable.addItemAt(item,index);
		}
		
		public function getItemAt(index:int, prefetch:int=0):Object
		{
			return foodtable.getItemAt(index,prefetch);
		}
		
		public function getItemIndex(item:Object):int
		{
			return foodtable.getItemIndex(item);
		}
		
		public function itemUpdated(item:Object, property:Object=null, oldValue:Object=null, newValue:Object=null):void
		{
			foodtable.itemUpdated(item,property,oldValue,newValue);
		}
		
		public function get length():int
		{
			return foodtable.length;
		}
		
		public function removeAll():void
		{
			foodtable.removeAll();
		}
		
		public function removeItemAt(index:int):Object
		{
			return foodtable.removeItemAt(index);;
		}
		
		public function setItemAt(item:Object, index:int):Object
		{
			return foodtable.setItemAt(item,index);;
		}
		
		public function toArray():Array
		{
			return foodtable.toArray();
		}
		
		public function addItem(item:Object):void
		{
			foodtable.addItem(item);
		}
		
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			foodtable.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return foodtable.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return foodtable.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			foodtable.removeEventListener(type,listener,useCapture);
		}
		
		public function willTrigger(type:String):Boolean
		{
			return foodtable.willTrigger(type);;
		}
		
	}
}