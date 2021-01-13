
$gtk.reset
attr_gtk
class Map_editor
	def initialize args
		@args = args

		@tileWidth = 32
		@menuWidth = 256
		@cameraOffset = 0 

		@height = 720/@tileWidth
		@width = 1280/@tileWidth
		@map = Array.new(@height){Array.new(@width){0}}

		@currentTile = 0

		@inMenu = false
		@currentTileMenu 

		initialize_buttons args
	end

	def initialize_buttons args
		#menu buttons
		border = 5
		w, h = @menuWidth - (border * 2), 50
		x, y,  = border, 720 - (h + border)

		tiles = new_button :tiles, x, y, w, h, "Tiles"
		entities = new_button :entities, x, y - (h + border), w, h, "Entities"

		@menuButtons = [
			tiles,
			entities
		]

		@back = new_button :back, x, y + 25, 50, 25, "Back"
	end

	def new_button id, x, y, w, h, text
		entity = { id: id, rect: { x: x, y: y, w: w, h: h } }

		 entity[:primitives] = [
		{ x: x, y: y, w: w, h: h, r: 220, g: 220, b: 220 }.solid,
		{ x: x, y: y+h, text: text, size_enum: 2, alignment_enum: 0 }.label,
		{ x: x, y: y, w: w, h: h}.border
		]
    
		entity
	end

	def new_button_sprite id, x, y, w, h, path
		entity = { id: id, rect: { x: x, y: y, w: w, h: h } }

		 entity[:primitives] = [
		{ x: x, y: y, w: w, h: h, path: path }.sprite,
		{ x: x, y: y, w: w, h: h}.border
		]
    
		entity
	end

	def button_clicked button
		return false unless args.inputs.mouse.click
		return args.inputs.mouse.point.inside_rect? button[:rect]
	end

	def render_background
		outputs.solids << [0, 0, 1280, 720, 100, 100, 100]
		outputs.labels << [10, 20, gtk.current_framerate]
	end

	def side_scroll
		#accelerate over time
		@cameraOffset -= 5 if args.inputs.keyboard.key_held.d && @cameraOffset > - @menuWidth - 10
		@cameraOffset += 5 if args.inputs.keyboard.key_held.a && @cameraOffset < 5
	end

	def keybinds
		@currentTile = "eraser" if args.inputs.keyboard.key_down.e
	end

	def render_map 
		@totalOffset = @menuWidth + @cameraOffset
		side_scroll
		for y in 0..(@height-1) do
			for x in 0..(@width-1) do
				id = @map[y][x]
				tileX, tileY = (x*@tileWidth) + @totalOffset + 5 , (y*@tileWidth)
				next if tileX < @menuWidth

				if id == 0 
					args.outputs.borders << { x: tileX, y: tileY, w: @tileWidth, h: @tileWidth, r: 255, g: 50, b: 50 }
				else
					spritePath = id
					outputs.sprites << { x: tileX, y: tileY, w: @tileWidth, h: @tileWidth, path: spritePath }
				end
			end
		end
	end

	#####################################################################
	def menu_button_logic
		for i in 0..(@menuButtons.length()-1) do
			break if @inMenu

			if button_clicked @menuButtons[i] 
				@inMenu = true
				@currentTileMenu = @menuButtons[i]
				@flag = true
			end
		end
	end

	def render_menu
		x, y, w, h = 0, 0, @menuWidth, 1280
		#make nicer graphic
		outputs.solids << [x, y, w, h, 200, 200, 200]

		menu_button_logic if @inMenu == false

		if @inMenu 
			render_tile_sprites 
		else 
			for i in 0..(@menuButtons.length()-1) do
				outputs.primitives << [@menuButtons[i][:primitives]]
			end
		end
		
	end

	def ls path
		@flag = false
		return `cmd /c "dir /b \"#{path}\""`.split("\r\n") #if $gtk.platform == 'Windows'
		#return `ls \"#{path}\"`.split("\n") if $gtk.platform == 'Linux' || $gtk.platform == 'Mac Os X'
	end

	def render_tile_sprites
		outputs.primitives << [@back[:primitives]]
		if button_clicked @back
			@inMenu = false
			@flag = false
			return
		end

		folderPath = "D:/dragonruby-windows-amd64/mygame/sprites/#{@currentTileMenu[:id]}"
		@menuSprites = ls(folderPath).select { |path| path.end_with? '.png' } if @flag
	

		headerX, headerY, headerW, headerH = 70, 720 - 30, 150, 25
		outputs.solids << [headerX, headerY, headerW, headerH, 220, 220, 220]
		outputs.labels << [headerX, headerY + headerH, @currentTileMenu[:id]]

		width = (@menuWidth/@tileWidth)-1 #7
		lastRow = @menuSprites.length() % width
		height = ((@menuSprites.length() - lastRow) / width) 

		border = 4
		x, y, w, fromTop = 0, -1, @tileWidth, 720-30-@tileWidth- border
		count = 0

		for x in 0..@menuSprites.length()-1 do
			y += 1 if x % width == 0
			x -= width * y
			outputs.sprites << { x: (x*w)+(border*(x+1)), y: fromTop-(y*w)-(border*y), w: w, h: w, path: "sprites/#{@currentTileMenu[:id]}/#{@menuSprites[count]}" }
			@currentTile = "sprites/#{@currentTileMenu[:id]}/#{@menuSprites[count]}" if menu_sprite_pressed (x*w)+(border*(x+1)), fromTop-(y*w), w, w
			count += 1 
		end
	end

	def menu_sprite_pressed x, y, w, h
		rect = { x: x, y: y, w: w, h: h}
		return false unless args.inputs.mouse.click
		return args.inputs.mouse.point.inside_rect? rect
	end

	######################################################################

	def tile_pressed
		mouseX, mouseY = args.inputs.mouse.point[0] - @totalOffset - 5, args.inputs.mouse.point[1]
		tempX, tempY = 0, 0
		for x in 0..(@width) do
			tempX = x -1
			break if x * @tileWidth > mouseX
		end
		
		for y in 0..(@height) do	
			tempY = y -1
			break if y * @tileWidth > mouseY
		end
		return [tempX, tempY]
	end
	
	def set_tile 
		temp = tile_pressed 
		x, y = temp[0], temp[1]
		tileX, tileY = (temp[0]*@tileWidth) + @totalOffset + 5 , (temp[1]*@tileWidth)

		if args.inputs.mouse.click && tileX >= @menuWidth
			if @map[y][x] == @currentTile || @currentTile == "eraser"
				@map[y][x] = 0
			else 
				@map[y][x] = @currentTile
			end
		end

		args.outputs.primitives << { x: tileX, y: tileY, w: @tileWidth, h: @tileWidth, r: 255, g: 255, b: 255 }.border if tileX >= @menuWidth

	end

	def tick
		render_background
		render_map
		keybinds
		set_tile
		render_menu
		puts @menuSprites if args.inputs.mouse.click
	end
end

def tick args
	$game ||= Map_editor.new(args)
	$game.args = args
	$game.tick
end
