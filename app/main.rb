# frozen_string_literal: true

def reset_sim()
  $setup_done = false
  $cells_checked = []
  $current_pixels = {}
  $render_pixels = []
  $iter_y = 0
end

def tick(args)
  $setup_done ||= false
  $cells_checked ||= 0
  $debug ||= false

  args.gtk.log_level = :off

  if $setup_done == false
    setup
    tick_output = []
    tick_output.unshift( { x: 640, y: 360, alignment_enum: 1, text: 'Loading...', r: 0,
                     g: 255, b: 0, primitive_marker: :label })
  else
    main_cycle

    $debug = !$debug if args.inputs.keyboard.key_up.tab
    if $debug
      tick_output ||= []
      tick_output.unshift({ x: 0, y: 720, text: "Sim Scale: #{$sim_scale}", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label })
      tick_output.unshift({ x: 0, y: 700, text: "FPS: #{args.gtk.current_framerate}", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label })
      percent = (($cells_checked / ((1280 / $sim_scale) * (720 / $sim_scale))))
      tick_output.unshift({ x: 0, y: 680, text: "Cells Checked: #{$cells_checked}/#{(1280 / $sim_scale) * (720 / $sim_scale)} - #{percent}", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label })
    end
  end

  tick_output ||= nil

  $render_pixels.unshift({ x: 0, y: 0, w: 1280, h: 720, a: 255, r: 0, g: 0, b: 0,
                           primitive_marker: :sprite, path: :pixel })

  args.outputs.sprites.concat($render_pixels)
  args.outputs.labels.concat(tick_output) if tick_output
end

def setup
  $start_density ||= 10 # 1/n chance of starting live
  $sim_scale ||= 4 # 1; 2; 4; 5; 8; 10; 16; 20; 40 and 80

  $current_pixels ||= {}

  $iter_y ||= 0
  iter_y = $iter_y
  iter_x = 0

  $render_pixels = []

  if iter_y < 720
    while iter_x < 1280
      if rand($start_density) == 0
        $current_pixels[iter_x] ||= {}
        $current_pixels[iter_x][iter_y] = PixelNew.new(iter_x, iter_y)
        $render_pixels.unshift($current_pixels[iter_x][iter_y])
      end
      iter_x += $sim_scale
    end
    iter_y += $sim_scale
  end
  $iter_y = iter_y

  $setup_done = true if $iter_y >= 720
end

def main_cycle
  next_tick = {}
  dead_cells_to_check = {}
  $cells_checked = 0

  $render_pixels = []

  iter_x = $current_pixels.length - 1
  temp_keys = $current_pixels.keys
  temp_values = $current_pixels.values

  while iter_x >= 0
    iter_y = temp_values[iter_x].length - 1
    $cells_checked += iter_y
    temp_x_keys = temp_values[iter_x].keys
    curr_x = temp_keys[iter_x]
    while iter_y >= 0
      curr_y = temp_x_keys[iter_y]
      neighbors = 0

      n_locs = [
        { x: curr_x - $sim_scale, y: curr_y - $sim_scale },
        { x: curr_x, y: curr_y - $sim_scale },
        { x: curr_x + $sim_scale, y: curr_y - $sim_scale },
        { x: curr_x - $sim_scale, y: curr_y },
        { x: curr_x + $sim_scale, y: curr_y },
        { x: curr_x - $sim_scale, y: curr_y + $sim_scale },
        { x: curr_x, y: curr_y + $sim_scale },
        { x: curr_x + $sim_scale, y: curr_y + $sim_scale }
      ]

      location_iter = 0

      while location_iter < 8
        location = n_locs[location_iter]
        location_iter += 1
        x = location[:x]
        y = location[:y]
        if (x) > 0 && x < 1280 && (y) > 0 && y < 720
          if $current_pixels.key?(x) && $current_pixels[x].key?(y)
            neighbors += 1
          else
            dead_cells_to_check[x] ||= {}
            dead_cells_to_check[x][y] ||= 0
            dead_cells_to_check[x][y] += 1
          end
        end
      end

      if neighbors == 2 || neighbors == 3
        next_tick[curr_x] ||= {}
        next_tick[curr_x][curr_y] = PixelNew.new(curr_x, curr_y)
        $render_pixels.unshift(next_tick[curr_x][curr_y])
      end
      iter_y -= 1
    end
    iter_x -= 1
  end

  iter_x = dead_cells_to_check.length - 1
  temp_keys = dead_cells_to_check.keys
  temp_values = dead_cells_to_check.values

  while iter_x >= 0
    iter_y = temp_values[iter_x].length - 1
    $cells_checked += iter_y
    temp_x_keys = temp_values[iter_x].keys
    curr_x = temp_keys[iter_x]
    column = temp_values[iter_x]
    while iter_y >= 0
      curr_y = temp_x_keys[iter_y]

      if column[curr_y] == 3
        next_tick[curr_x] ||= {}
        next_tick[curr_x][curr_y] = PixelNew.new(curr_x, curr_y)
        $render_pixels.unshift(next_tick[curr_x][curr_y])
      end
      iter_y -= 1
    end
    iter_x -= 1
  end
  $current_pixels = next_tick
end

# Class to remove erronious draw calls
class PixelNew
  attr_sprite
  def initialize(x, y)
    @x = x
    @y = y
  end

  def draw_override(ffi)
    ffi.draw_sprite(@x, @y, $sim_scale, $sim_scale, 'pixel')
  end

  def serialize; {}; end; # This is to make the engine keep quiet about the custom pixel class.
end
