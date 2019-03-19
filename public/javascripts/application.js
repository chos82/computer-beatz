// initializer - put all functions into init()
Event.observe(window, 'load', init);
	function init(){
		makeItCount('text-3000', 3000);
		makeItCount('text-500', 500);
		new Tooltip();
		new CheckUser();
		new EditLink();
		Blinder.init();
		UserMenu.init();
		PlayableLinks.init();
		Bookmark.init();
	}
	
	var Bookmark = {
		init: function(){
			social = $('socialize')
			if(social != null)
				social.show();
			this.bm = $('bookmarks');
			this.bt = $('bookmark_button');
			this.bt.observe('click', Bookmark.click.bind(this));
			this.closeButton = $('bookmarks_close');
			this.closeButton.observe('click', Bookmark.close.bind(this));
		},
		click: function(event){
			event.stop();
			if( !this.bm.visible() )
				Effect.BlindDown(this.bm);
			else
				Effect.BlindUp(this.bm);
		},
		close: function(event){
			event.stop();
			Effect.BlindUp(this.bm);
		}
	}
	
	var UserMenu = {
		init: function(){
			var upm = $('user-profile-menu');
			if(upm != null){
				upm.hide();
			}
			this.login = $('loginName');
			if(this.login != null){
				this.login.observe('mouseover', UserMenu.loginOver.bind(this));
				this.login.observe('mouseout', UserMenu.loginOut.bind(this));
			}
		},
		loginOver: function(event){
			$('userJSmenu').show();
		},
		loginOut: function(event){
			$('userJSmenu').hide();
		}
	};
	
	var Blinder = {
		init: function(){
			var uppers = $$('.blindUp');
			for(i=0;i<uppers.length;i++){
				uppers[i].stopObserving();
				uppers[i].observe('click', Blinder.blindUp.bind(uppers[i]));
			}
			var downers=$$('.blindDown');
			for(i=0;i<downers.length;i++){
				downers[i].stopObserving();
				downers[i].observe('click', Blinder.blindDown.bind(downers[i]));
			}
			var saveButton = $('save');
			if (saveButton != null) {
				saveButton.observe('mouseover', Tagging.saveHover.bind(saveButton));
				saveButton.observe('mouseout', Tagging.saveLink.bind(saveButton));
			}
		},
		blindUp: function(event){
			event.stop();
			var blinderNo = this.readAttribute('id').substr(3,2);
			Effect.Squish($('blindable-'+blinderNo));
			var uppers=$$('.blindUp')
			$('bd-'+blinderNo).addClassName('blindDown').removeClassName('blindUp');
			init();
		},
		blindDown: function(event){
			event.stop();
			Effect.Grow($('blindable-'+this.readAttribute('id').substr(3,2)));
			this.addClassName('blindUp');
			this.removeClassName('blindDown');
			init();
		}
	};
	
	var EditLink = Class.create({
		initialize: function(){
			var editables = $$('.edit-link');
			for(i=0; i < editables.length; i++){
				editables[i].observe( 'click', this.request.bind(editables[i]) );
			}
		},
		request: function(event){
			var id = this.readAttribute('id');
			var url = this.readAttribute('href');
			var editDivs = $$('.add-tag');
			for(i=0; i < editDivs.length; i++){
				if(editDivs[i].visible()){
					Effect.Shrink(editDivs[i]);
					editDivs[i].update();
				}
			}
			var editLinks = $$('.edit-link');
			for(i=0; i<editLinks.length; i++){
				editLinks[i].show();
			}
			var spinner = $('spinner-'+id);
			spinner.show();
			new Ajax.Request( url, { 
				method: 'get',
				onComplete: function(){
					Effect.BlindUp(spinner);
					Tagging.init(id);
				}
			} );
			event.stop();
		},
	})
	
	var CheckUser = Class.create({
		name: null,
		initialize: function(){
			var field1 = $('message_reciever');
			var field2 = $('invitation_reciever');
			if(field1 != null)
				this.url = 'check_reciever';
			else
				this.url = '../check_reciever';
			this.formField = field1 || field2;
			this.pendingRequests = 0;
			this.chars2eval = 0;
			this.spinner = $('spinner-reciever');
			if (this.formField != null) {
				this.formField.observe('keyup', this.reciever.bind(this));
				var results=$$('.auto_complete');
				for(i=0;i<results.length;i++){
					results[i].observe('keyup', this.reciever.bind(this));
					results[i].observe('click', this.reciever.bind(this));
				}
			}
		},
		reciever: function(){
			var tempName = $F(this.formField);
			if (this.name != tempName) {
				this.name = tempName;
				if (this.name.length > 2) {
					this.opt = {
						parameters: 'reciever=' + this.name,
						onComplete: this.onComplete.bind(this),
						onSuccess: function(response){
							$('reciever_status').update(response.responseText);
						}
					};
					this.request.bind(this).delay(1.5);
				}else{
					$('reciever_status').update(' ');
					this.spinner.hide();
				}
			}
		},
		request: function(){
			if(this.name == $F(this.formField)){
				this.spinner.show();
				this.pendingRequests++;
				new Ajax.Request(this.url, this.opt);
			}
		},
		onComplete: function(){
			this.pendingRequests--;
			if (this.pendingRequests == 0)
				this.spinner.hide();
		}
	})
	
	var Tagging = {
		init: function(idSuffix) {
			this.idSuffix = idSuffix != null ? idSuffix : '';
			this.formField = $('tag_text');
			taggings = $$('.tag');
			for( var i = 0; i < taggings.length; i++){
				taggings[i].observe( 'mouseover', this.hover.bind(taggings[i]) );
				taggings[i].observe( 'mouseout', this.link.bind(taggings[i]) );
				taggings[i].bAdd = this.add.bind(taggings[i], this.formField);
				taggings[i].bRemove = this.remove.bind(taggings[i], this.formField);
				if(taggings[i].hasClassName('removable'))
					taggings[i].observe( 'click', taggings[i].bRemove )
				else
					taggings[i].observe( 'click', taggings[i].bAdd );
			}
			this.formField.observe('keyup', Tagging.change.bind(this.formField, taggings));
			var cancelButton = $('cancel');
			cancelButton.observe('click', this.cancel.bind(cancelButton));
			var saveButton = $('save');
			saveButton.observe('mouseover', this.saveHover.bind(saveButton));
			saveButton.observe('mouseout', this.saveLink.bind(saveButton));
		},
		saveLink: function(){
			this.setStyle({
				backgroundColor: '#bbb',
				borderColor: '#bbb',
				'color': '#4e8334'
			});
		},
		saveHover: function(){
			this.setStyle({
				backgroundColor: '#666',
				'border': '1px solid #97c86a',
				'color': '#97c86a'
			});
		},
		cancel: function(event){
			element = $('manage-tags') || $('manage-tags-'+Tagging.idSuffix);
			Effect.Shrink(element);
			element.update();
			event.stop();
			var element2show = $('tags-link');
			element2show = element2show != null ? element2show : $(Tagging.idSuffix);
			Effect.BlindDown(element2show);
			tooltip = $('tag-button_tipBox')
			if(tooltip)
				tooltip.show();
		},
		change: function(taggings){
			var text = $F(this);
			for(var i=0; i<taggings.length; i++){
				taggings[i].stopObserving('click');
				var tag = taggings[i].innerText || taggings[i].textContent;
				if(text.match(new RegExp('.*'+tag+'.*'))){
					Tagging.makeRemovable(taggings[i]);
				} else{
					Tagging.makeAddable(taggings[i]);
				}
			}
		},
		hover: function (){
			this.setStyle({
				backgroundColor: '#666',
				'color': 'white'
			});
		},
		link: function(){
			if(this.hasClassName('addable')){
				this.setStyle({
					backgroundColor: 'transparent',
					'color': '#00f'
				});
			} else if(this.hasClassName('removable')){
				this.setStyle({
					backgroundColor: '#bbb',
					'color': 'white'
				});
			}
		},
		add: function(form){
			this.stopObserving('click', this.bAdd);
			var tag = this.innerText || this.textContent;
			var text = $F(form);
			text = text.length == 0 ? tag : text+' '+tag;
			form.setValue(text);
			Tagging.makeRemovable(this);
		},
		makeRemovable: function(item){
			item.removeClassName('addable').addClassName('removable');
			item.setStyle({
				backgroundColor: '#bbb',
				'color': 'white'
			});
			item.observe( 'click', item.bRemove );
		},
		remove: function(form){
			this.stopObserving('click', this.bRemove);
			var tag = this.innerText || this.textContent;
			var text = $F(form);
			//var regexp = new RegExp('(,\\s*)*'+tag);
			//text = text.gsub(regexp, '').gsub(/^,\s*/, '');
			var regexp = new RegExp('\\s*'+tag);
			text = text.gsub(regexp, '').gsub(/^\s+/, '');
			form.setValue(text);
			Tagging.makeAddable(this);
		},
		makeAddable: function(item){
			item.removeClassName('removable').addClassName('addable');
			item.setStyle({
				backgroundColor: 'transparent',
				'color': '#00f'
			});
			item.observe( 'click', item.bAdd );
		}
	}
	
	var Tooltip = Class.create( { 
		initialize: function(){
			/*
			 * Collect all items with class="tooltip[ otherClass]*"
			 * show the item`s tile in the element with id="<item.id>+'_tipBox'
			 */ 
			var tippables = $$('.tooltip')
			for( var i = 0; i < tippables.length; i++){
				tippables[i].observe( 'mouseover', this.showToolTip.bind(tippables[i]) );
				tippables[i].observe( 'mouseout', this.hideToolTip.bind(tippables[i]) );
				tippables[i].observe( 'click', this.request.bind(tippables[i]) );
			}
		},
		request: function(event){
			var tipBox = $(this.readAttribute('id') + '_tipBox');
			if ( tipBox != null ) {
				this.writeAttribute('title', this.tipText);
				tipBox.update('&nbsp;');
			}
			Effect.BlindUp($(this.readAttribute('id') + '_tipBox'));
			var url = this.readAttribute('href');
			var spinner = $( this.readAttribute('id') + '_spinner' );
			spinner.show();
			new Ajax.Request( url, { 
				method: 'get',
				onComplete: function(){
					spinner.hide();
					Tagging.init();
				}
			} );
			event.stop();
		},
		showToolTip: function(){
			this.tipText = this.readAttribute('title');
			this.writeAttribute('title', '');
			var tipBox = $(this.readAttribute('id') + '_tipBox');
			if( this.tipText != null && tipBox != null ) {
				tipBox.update(this.tipText);
			}
		},
		hideToolTip: function(){
			var tipBox = $(this.readAttribute('id') + '_tipBox');
			if ( tipBox != null ) {
				this.writeAttribute('title', this.tipText);
				tipBox.update('&nbsp;');
			}
		}
	} );
	
// counter for text areas	
	function charCounter(id, maxlimit, limited){
		if (!$('counter-'+id)){
			$(id).insert({after: '<div id="counter-'+id+'"></div>'});
		}
		if($F(id).length >= maxlimit){
			if(limited){	$(id).value = $F(id).substring(0, maxlimit); }
			$('counter-'+id).addClassName('charcount-limit');
			$('counter-'+id).removeClassName('charcount-safe');
		} else {	
			$('counter-'+id).removeClassName('charcount-limit');
			$('counter-'+id).addClassName('charcount-safe');
		}
		$('counter-'+id).update( $F(id).length + '/' + maxlimit );	
	}
	
	function makeItCount(id, maxsize, limited){
		if(limited == null) limited = true;
		if ($(id)){
			Event.observe($(id), 'keyup', function(){charCounter(id, maxsize, limited);}, false);
			Event.observe($(id), 'keydown', function(){charCounter(id, maxsize, limited);}, false);
			charCounter(id,maxsize,limited);
		}
	}

	var PlayableLinks = {
		init: function(){
			links = $$('.playable')
			for(i=0; i<links.length; i++){
				links[i].observe('click', this.click_link.bind(links[i]))
			}
		},
		click_link: function(event){
			event.stop();
			element = Event.element(event);
			element = element.hasClassName('playable') ? element : element.up('.playable');
			if (element.hasClassName('projectPlay')) {
				id = element.next().innerHTML
				window.open('http://' + location.hostname + ':3000/player/' + id + '/project', 'Player', 'innerHeight=340,innerWidth=590,scrollbars=no,dependent=yes,location=no,menubar=no,resizable=no,status=no,toolbar=no');
			} else if (element.hasClassName('playAll')) {
				window.open('http://' + location.hostname + ':3000/player/all', 'Player', 'innerHeight=340,innerWidth=590,scrollbars=no,dependent=yes,location=no,menubar=no,resizable=no,status=no,toolbar=no');
			}
			else {
				id = element.next().innerHTML
				window.open('http://' + location.hostname + ':3000/player/' + id + '/single', 'Player', 'innerHeight=340,innerWidth=590,scrollbars=no,dependent=yes,location=no,menubar=no,resizable=no,status=no,toolbar=no');
			}
		}
	}
	