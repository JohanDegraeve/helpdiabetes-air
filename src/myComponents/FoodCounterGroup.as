/**
 Copyright (C) 2011  hippoandfriends
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
/**
 * not yet used, seems not working very good
 * goal was to have a list on the right of the foodcounterview, from where a character could be selected 
*/
package myComponents
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.events.TouchEvent;
	import flash.geom.Rectangle;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.Timer;
	
	import flashx.textLayout.utils.CharacterUtil;
	
	import model.ModelLocator;
	
	import mx.collections.ArrayCollection;
	import mx.effects.easing.Exponential;
	import mx.events.IndexChangedEvent;
	import mx.utils.OnDemandEventDispatcher;
	
	import spark.components.List;
	import spark.components.VGroup;
	import spark.components.supportClasses.StyleableTextField;
	
	public class FoodCounterGroup extends VGroup
	{
		
		
		/**
		 * the currently selected character shown in the middle of the screen 
		 */
		private var selectedCharacter:StyleableTextField;
		/**
		 * determines if selectedCharacter and also before and after are added as child or not
		 */
		private var selectedCharacterDisplayed:Boolean = false;

		/**
		 * the character just before the currently selected character shown in the middle of the screen 
		 */
		private var beforeSelectedCharacter:StyleableTextField;
		/**
		 * the character just after the currently selected character shown in the middle of the screen 
		 */
		private var afterSelectedCharacter:StyleableTextField;
		
		/**
		 * styleabletextfield that contains the searchtext entered by the user<br>
		 */
		private var searchText:StyleableTextField;
		
		private function confirmSearchText():void {
			if (searchText)
				searchText.htmlText = searchTextAsString;
			searchTextConfirmed = true;
		}
		
		private function unConfirmSearchText():void {
			if (searchText) {
				searchText.htmlText = "<i>"+searchTextAsString  +"</i>";
			}
			searchTextConfirmed = false;
		}
		
		private function addCharacterToSearchText(newCharacter:String):void {
			if (newCharacter == "<") {
				var charactersToDelete:int = 1;
				//first check if it was less than 400 ms that previous < was received
				if (confirmTimer)
					if (confirmTimer.running) {
						confirmTimer.stop();
					}
				if (deleteTimer)
					if (deleteTimer.running) {
						return;
					}
				
				if (!searchTextConfirmed && searchTextAsString.length > 1)
					charactersToDelete = 2;
				if (searchTextAsString.length > 0) {
					searchTextAsString = searchTextAsString.substr(0, searchTextAsString.length - charactersToDelete);
				}
				confirmSearchText();
				deleteTimer = new Timer(400, 1);
				deleteTimer.start();
				return;
			}
			if (searchTextConfirmed) {
				searchTextAsString += newCharacter;
			}
			else {
				if (searchTextAsString.length > 0) {
					searchTextAsString = searchTextAsString.substr(0, searchTextAsString.length - 1) + newCharacter;
				}
				else {
					searchTextAsString = newCharacter;
				}
			}
			unConfirmSearchText();
		}
		
		private var searchTextConfirmed:Boolean = true;
		private var searchTextAsString:String = "";
		
		/**
		 * the fooditem list 
		 */
		private var foodItemList:List;
		
		private var _dataProvider:ArrayCollection;
		
		/**
		 * if true then version that is slower will be used 
		 */
		private const slow:Boolean = false;
		
		/**
		 * The data provider for this DataGroup. It must be an IList.
		 * There are several IList implementations included in the Flex framework, including ArrayCollection, ArrayList, and XMLListCollection.
		 */
		public function get dataProvider():ArrayCollection
		{
			return _dataProvider;
		}
		
		/**
		 * @private
		 */
		public function set dataProvider(value:ArrayCollection):void
		{
			if (value == _dataProvider)
				return;
			_dataProvider = value;
			if (foodItemList) {
				foodItemList.dataProvider = value;
				invalidateDisplayList();
			}
		}
		
		private var _change:Function;
		
		/**
		 * Same as change property in list<br>
		 * Here the doc for list:<br>
		 * Dispatched after the selection has changed. This event is dispatched when the user interacts with the control. 
		 */
		public function get change():Function
		{
			return _change;
		}
		
		/**
		 * @private
		 */
		public function set change(value:Function):void
		{
			_change = value;
		}
		
		private var _foodItemListWidth:int = 297;
		
		/**
		 * explicit width of the list, default value = 297
		 */
		public function get foodItemListWidth():int
		{
			return _foodItemListWidth;
		}
		
		/**
		 * @private
		 */
		public function set foodItemListWidth(value:int):void
		{
			if (value == _foodItemListWidth)
				return;
			_foodItemListWidth = value;
			invalidateDisplayList();
		}
		
		private var _alphabetListWidth:int = 23;
		
		/**
		 * explicit width of the alphabetlist, default value = 23 
		 */
		public function get alphabetListWidth():int
		{
			return _alphabetListWidth;
		}
		
		/**
		 * @private
		 */
		public function set alphabetListWidth(value:int):void
		{
			if (value == _alphabetListWidth)
				return;
			_alphabetListWidth = value;
			invalidateDisplayList();
		}
		
		/**
		 * arraycollection of stylebletextfields, each one with a letter as label 
		 */
		private var alphabet:ArrayCollection;	
		
		/**
		 * index of the highligted alphabet, if -1 then none is. 
		 */
		private var highlightedLetter:int = -1;
		
		private static var alphabetElementHeight:int = 0;//height to be used for a character
		private static var fontHeight:int;//fontheight for characterprinted within styleabletextfield
		//private static var topOffset:int ;//offset for character printed within styleabletextfield
		private static var offsetIfNoCharacterHighlighted:int;//position y of first character in case no character is highlighted
		
		
		/**
		 * timer used for confirming letter, if expired, then letter changes from inversed printed to normal printed 
		 */
		private var confirmTimer:Timer;
		/**
		 * timer used for successive deletions, if < is received while timer still running then it will be ignored. 
		 */
		private var deleteTimer:Timer;
		
		private var StyleableTextfieldPaddingTop:int = -1;
		private var StyleableTextfieldPaddingBottom:int;
		private var fontSizeForSearchField:int;
		
		/**
		 * used in placing alphabet styleabletextfields<br>
		 * index is reference into alphabet arraycollection<br>
		 * a value of -1 means there's no element and that y value 
		 */
		private var yToIndex:Vector.<int>; 
		/**
		 * used in placing alphabet styleabletextfields<br>
		 * index is reference into alphabet arraycollection
		 */
		private var indexToY:Vector.<int>; 
		
		
		
		
		public function FoodCounterGroup()
		{
			super();
			if (StyleableTextfieldPaddingTop == -1) {
				StyleableTextfieldPaddingTop    = styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("paddingTop");
				StyleableTextfieldPaddingBottom = styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("paddingBottom");
			}
		}
		
		override protected function measure():void {
			//if I would just use super.measure here then the measuredheight would be the sum of the heights of all alphabet styleabletextfields - 27 in total
			measuredWidth = parent.width;
			measuredHeight = parent.height;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			searchText.setLayoutBoundsSize(foodItemListWidth, 40);
			searchText.setLayoutBoundsPosition(0,StyleableTextfieldPaddingTop);
			
			foodItemList.setLayoutBoundsSize(foodItemListWidth,unscaledHeight - (StyleableTextfieldPaddingTop + 30 + StyleableTextfieldPaddingBottom));
			foodItemList.setLayoutBoundsPosition(0,StyleableTextfieldPaddingTop + 30 + StyleableTextfieldPaddingBottom);
			
			if (alphabetElementHeight == 0) {
				//highlighted element = 3 * height of normal element
				//highlighted element - 1 and + 1 = 2 * height of normal element
				//highlighted element - 2 and +2 = 1,5 * height of normal element
				//26 characters in alphabet + '<' = 27,  
				//...then add space for the oversized elements = 27 + 2 (for the highlighted element) + 2 (highlighted + 1 and - 1) + 1
				alphabetElementHeight = unscaledHeight/(slow ? 32 : 27);
				fontHeight = alphabetElementHeight*0.9;
				//topOffset = alphabetElementHeight*0.05;
				offsetIfNoCharacterHighlighted = (unscaledHeight - alphabetElementHeight *27)/2; //2 (for the highlighted element) + 2 (highlighted + 1 and - 1) + 1
				initializeYtoIndexAndIndextoY(unscaledHeight);
			}
			for (var j:int = 0;j < alphabet.length;j++) {
				var multiplicationFactor:Number;
				
				if (highlightedLetter == -1)
					multiplicationFactor = 1;
				else if (j == highlightedLetter)  
					multiplicationFactor = 3;
				else if ((j == highlightedLetter - 1) || (j == highlightedLetter + 1))
					multiplicationFactor = 2;
				else if ((j == highlightedLetter - 2) || (j == highlightedLetter + 2))
					multiplicationFactor = 1.5;
				else multiplicationFactor = 1;
				(alphabet.getItemAt(j) as StyleableTextField).setStyle("fontSize",fontHeight * (slow ? multiplicationFactor : 1));
				(alphabet.getItemAt(j) as StyleableTextField).setLayoutBoundsSize(alphabetListWidth,indexToY[j + 1] - indexToY[j]);
				(alphabet.getItemAt(j) as StyleableTextField).setLayoutBoundsPosition(foodItemListWidth,indexToY[j]);
			}
			if (highlightedLetter > -1) {
				addElement(selectedCharacter);
				addElement(beforeSelectedCharacter);
				addElement(afterSelectedCharacter);
				selectedCharacterDisplayed = true

				selectedCharacter.setLayoutBoundsSize(alphabetListWidth,alphabetElementHeight);
				selectedCharacter.setLayoutBoundsPosition((unscaledWidth - alphabetListWidth)/2,(unscaledHeight - alphabetElementHeight)/2 );
				beforeSelectedCharacter.setLayoutBoundsSize(alphabetListWidth,alphabetElementHeight);
				beforeSelectedCharacter.setLayoutBoundsPosition((unscaledWidth - alphabetListWidth)/2,(unscaledHeight - alphabetElementHeight)/2 - alphabetElementHeight*2);
				afterSelectedCharacter.setLayoutBoundsSize(alphabetListWidth,alphabetElementHeight);
				afterSelectedCharacter.setLayoutBoundsPosition((unscaledWidth - alphabetListWidth)/2,(unscaledHeight - alphabetElementHeight)/2 + alphabetElementHeight*2);
			} else {
				if (selectedCharacterDisplayed) {
					removeElement(selectedCharacter);
					removeElement(beforeSelectedCharacter);
					removeElement(afterSelectedCharacter);
					selectedCharacterDisplayed = false;
				}
			}
		}
		
		private function displayFoodItem(item:Object):String {
			return item.itemDescription;
		}
		
		override protected function createChildren():void  {
			if (!foodItemList) {
				foodItemList = new List();
				foodItemList.left = 0;
				foodItemList.right = 0;
				foodItemList.bottom = 0;
				foodItemList.top = 0;
				foodItemList.labelFunction = displayFoodItem;
				foodItemList.addEventListener(Event.CHANGE,change);
				if (dataProvider != null)
					foodItemList.dataProvider = dataProvider;
				addElement(foodItemList);
			}
			
			if (!searchText) {
				searchText = new StyleableTextField();
				searchText.styleName = this;
				searchText.editable = false;
				searchText.multiline = false;
				searchText.wordWrap = false;
				searchText.htmlText = "";
				fontSizeForSearchField = searchText.getStyle("fontSize");
				addElement(searchText);
			}
			
			
			if (!selectedCharacter) {
				selectedCharacter = new StyleableTextField();
				beforeSelectedCharacter = new StyleableTextField();
				afterSelectedCharacter = new StyleableTextField();
				selectedCharacter.styleName = this;
				selectedCharacter.editable = false;
				selectedCharacter.multiline = false;
				selectedCharacter.wordWrap = false;
				selectedCharacter.text = "";
				selectedCharacter.background = true;
				afterSelectedCharacter.styleName = this;
				afterSelectedCharacter.editable = false;
				afterSelectedCharacter.multiline = false;
				afterSelectedCharacter.wordWrap = false;
				afterSelectedCharacter.text = "";
				afterSelectedCharacter.background = true;
				beforeSelectedCharacter.styleName = this;
				beforeSelectedCharacter.editable = false;
				beforeSelectedCharacter.multiline = false;
				beforeSelectedCharacter.wordWrap = false;
				beforeSelectedCharacter.text = "";
				beforeSelectedCharacter.background = true;
			}
			
			if (!alphabet) {
				alphabet = new ArrayCollection();
				for (var i:int = 0;i < 26;i++) {
					var letter:StyleableTextField = new StyleableTextField();
					letter.styleName = this;
					letter.editable = false;
					//(alphabet.getItemAt(i) as StyleableTextField).setStyle("textAlign","center");
					letter.text = String.fromCharCode(97 + i);
					alphabet.addItem(letter);
					addElement(letter);
				}
				letter = new StyleableTextField();
				letter.styleName = this;
				letter.editable = false;
				//(alphabet.getItemAt(i) as StyleableTextField).setStyle("textAlign","center");
				letter.text = "<";
				alphabet.addItem(letter);
				addElement(letter);
			}
		}
		
		override public function initialize():void {
			super.initialize();
			addEventListener(MouseEvent.MOUSE_DOWN,onTouchBegin);
			addEventListener(MouseEvent.MOUSE_UP,onTouchEnd);
		}
		
		private function onTouchBegin(eBegin:MouseEvent):void {
			
			if ((eBegin.currentTarget as FoodCounterGroup).mouseX < foodItemListWidth)
				return;
			if (confirmTimer)
				if (confirmTimer.running) {
					confirmTimer.stop();
				}
			var mouseYPosition:int = (eBegin.currentTarget as FoodCounterGroup).mouseY;
			
			if (yToIndex[mouseYPosition] > -1)//it's a character
			{
				if (confirmTimer)
					if (confirmTimer.running) {
						confirmTimer.stop();
					}
				
				/*if ( (97 <= ((eBegin.target) as StyleableTextField).text.charCodeAt(0)) &&   ((97 + 25) >= ((eBegin.target) as StyleableTextField).text.charCodeAt(0)))
				highlightedLetter = ((eBegin.target) as StyleableTextField).text.charCodeAt(0) - 97;
				else
				highlightedLetter = 26;*/
				highlightedLetter = yToIndex[mouseYPosition];
				
				addCharacterToSearchText((alphabet.getItemAt(highlightedLetter) as StyleableTextField).text);
				selectedCharacter.text = (alphabet.getItemAt(highlightedLetter) as StyleableTextField).text;
				if (highlightedLetter < alphabet.length)
					afterSelectedCharacter.text = (alphabet.getItemAt(highlightedLetter + 1) as StyleableTextField).text;
				else
					afterSelectedCharacter.text = "";
				if (highlightedLetter > 0)
					beforeSelectedCharacter.text = (alphabet.getItemAt(highlightedLetter - 1) as StyleableTextField).text;
				else 
					beforeSelectedCharacter.text = "";
				if (slow)
					repositionAlphabet(mouseYPosition - indexToY[yToIndex[mouseYPosition]],yToIndex[mouseYPosition],mouseYPosition);
				invalidateDisplayList();
			}
			addEventListener(MouseEvent.MOUSE_MOVE,onTouchMove);
		}
		
		private function onTouchEnd(eEnd:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_MOVE,onTouchMove);
			confirmTimer = new Timer(400, 1);
			confirmTimer.addEventListener(TimerEvent.TIMER_COMPLETE, confirmLetter);
			confirmTimer.start();
		}
		
		private function onTouchMove(eMove:MouseEvent):void {
			if ((eMove.currentTarget as FoodCounterGroup).mouseX < foodItemListWidth)
				return;
			
			removeEventListener(MouseEvent.MOUSE_MOVE,onTouchMove);
			
			if (confirmTimer)
				if (confirmTimer.running) {
					confirmTimer.stop();
				}
			
			var mouseYPosition:int = (eMove.currentTarget as FoodCounterGroup).mouseY;
			
			if (yToIndex[mouseYPosition] > -1)//it's a character
			{
				var previousLetter:int = highlightedLetter;
				/*if ( (97 <= ((eMove.target) as StyleableTextField).text.charCodeAt(0)) &&   ((97 + 25) >= ((eMove.target) as StyleableTextField).text.charCodeAt(0)))
				highlightedLetter = ((eMove.target) as StyleableTextField).text.charCodeAt(0) - 97;
				else
				highlightedLetter = 26;*/
				highlightedLetter = yToIndex[mouseYPosition];
				if (highlightedLetter != previousLetter) {
					addCharacterToSearchText((alphabet.getItemAt(highlightedLetter) as StyleableTextField).text);
					selectedCharacter.text = (alphabet.getItemAt(highlightedLetter) as StyleableTextField).text;
					if (highlightedLetter < alphabet.length)
						afterSelectedCharacter.text = (alphabet.getItemAt(highlightedLetter + 1) as StyleableTextField).text;
					else
						afterSelectedCharacter.text = "";
					if (highlightedLetter > 0)
						beforeSelectedCharacter.text = (alphabet.getItemAt(highlightedLetter - 1) as StyleableTextField).text;
					else 
						beforeSelectedCharacter.text = "";
					if (slow)
						repositionAlphabet(mouseYPosition - indexToY[yToIndex[mouseYPosition]],yToIndex[mouseYPosition],mouseYPosition);
					invalidateDisplayList();
				}
			}
			addEventListener(MouseEvent.MOUSE_MOVE,onTouchMove);
		}
		
		private function confirmLetter(evt:TimerEvent):void {
			highlightedLetter = -1;
			initializeYtoIndexAndIndextoY(yToIndex.length);
			invalidateDisplayList();//because highlightedLetter is set to 0, so the resizing of the characters is necessary
			confirmSearchText();
		}
		
		/**
		 * speaks for itself, if yToIndex == null then a new Vector is assigned to yToIndex and also to indexToY<br>
		 * in any case reinitialized yToIndex and indexToY, assuming no element is highlighted<br>
		 * also reset highlightedLetter to -1 
		 */
		private function initializeYtoIndexAndIndextoY( maxY:int):void {
			if (yToIndex == null) {
				yToIndex = new Vector.<int>();
				indexToY = new Vector.<int>();
			}
			for (var i:int = 0;i < maxY; i ++)
				yToIndex[i] = -1;//by default no element shown
			
			var currentHeight:Number = offsetIfNoCharacterHighlighted;
			for (var j:int = 0;j < alphabet.length;j++) {
				indexToY[j] = currentHeight;
				for (; currentHeight < indexToY[j] + alphabetElementHeight;currentHeight++) {
					yToIndex[currentHeight] = j;
				}
			}
			indexToY[j] = currentHeight;//just adding an element not really matching a real element, but to know the size of the last element
		}
		
		/**
		 * will reposition the alphabet, localYPosition =  the y index of the mouse where the element was hit, locally within the element<br>
		 * elementIndex = index into alphabet of the element that was touched and that needs to be shown highlighted<br>
		 * yPosition = the y index of the mouse<br>
		 */
		private function repositionAlphabet(localYPosition:int,elementIndex:int,yPosition:int):void {
			//the size of the hit element
			var elementSize:int = indexToY[elementIndex + 1] - indexToY[elementIndex];
			//postion of the mouse, relative within the element
			var relativeMousePosition:Number = localYPosition/elementSize;
			var multiplicationFactor:Number;
			var j:int;
			var i:int
			
			if (highlightedLetter == -1)
				multiplicationFactor = 1;
			else if (elementIndex == highlightedLetter)  
				multiplicationFactor = 3;
			else if ((elementIndex == highlightedLetter - 1) || (elementIndex == highlightedLetter + 1))
				multiplicationFactor = 2;
			else if ((elementIndex == highlightedLetter - 2) || (elementIndex == highlightedLetter + 2))
				multiplicationFactor = 1.5;
			else multiplicationFactor = 1;
			
			//goal is to put the element again on the same relative position, relative to yPostion, but keeping in mind the possible changed size
			indexToY[elementIndex] = Math.max(0,yPosition - alphabetElementHeight * multiplicationFactor * relativeMousePosition);
			for (i = indexToY[elementIndex]; i < indexToY[elementIndex] + alphabetElementHeight * multiplicationFactor;i++)
				yToIndex[i] = elementIndex;
			indexToY[elementIndex + 1] = indexToY[elementIndex] + alphabetElementHeight * multiplicationFactor;//setting the next element already
			
			//do the same for all previous elements
			for (j = elementIndex - 1;j >= 0;j--) {
				if (highlightedLetter == -1)
					multiplicationFactor = 1;
				else if (j == highlightedLetter)  
					multiplicationFactor = 3;
				else if ((j == highlightedLetter - 1) || (j == highlightedLetter + 1))
					multiplicationFactor = 2;
				else if ((j == highlightedLetter - 2) || (j == highlightedLetter + 2))
					multiplicationFactor = 1.5;
				else multiplicationFactor = 1;
				
				indexToY[j] = indexToY[j + 1] - alphabetElementHeight * multiplicationFactor;
				for (i = indexToY[j]; i < indexToY[j] + alphabetElementHeight * multiplicationFactor;i++)
					if ( (i >= 0) && (i < yToIndex.length))//it may happen that i < 0 namely for example first alphabet elements will be put out of the screen
						yToIndex[i] = j;
			}
			
			//do the same for all next elements
			for (j = elementIndex + 1;j < alphabet.length;j++) {
				if (highlightedLetter == -1)
					multiplicationFactor = 1;
				else if (j == highlightedLetter)  
					multiplicationFactor = 3;
				else if ((j == highlightedLetter - 1) || (j == highlightedLetter + 1))
					multiplicationFactor = 2;
				else if ((j == highlightedLetter - 2) || (j == highlightedLetter + 2))
					multiplicationFactor = 1.5;
				else multiplicationFactor = 1;
				
				//indexToY[j] has already been set in the statement indexToY[elementIndex + 1] = indexToY[elementIndex] + alphabetElementHeight * multiplicationFactor;
				//indexToY[j] = indexToY[j - 1] + alphabetElementHeight * multiplicationFactor;
				for (i = indexToY[j]; i < indexToY[j] + alphabetElementHeight * multiplicationFactor;i++)
					if ( (i >= 0) && (i < yToIndex.length))//it may happen that i < 0 namely for example first alphabet elements will be put out of the screen
						yToIndex[i] = j;
				indexToY[j+1] = indexToY[j] + alphabetElementHeight * multiplicationFactor;				
			}
		}
	}
}