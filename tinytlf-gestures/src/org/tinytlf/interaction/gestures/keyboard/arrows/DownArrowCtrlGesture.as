package org.tinytlf.interaction.gestures.keyboard.arrows
{
	import flash.events.KeyboardEvent;
	
	import org.tinytlf.util.TinytlfUtil;
	
	[Event("keyDown")]
	
	public class DownArrowCtrlGesture extends DownArrowGesture
	{
		override public function down(event:KeyboardEvent):Boolean
		{
			return super.down(event) && (TinytlfUtil.isMac() ? event.altKey : event.ctrlKey);
		}
	}
}