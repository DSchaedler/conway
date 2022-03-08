# frozen_string_literal: true

# 1; 2; 4; 5; 8; 10; 16; 20; 40 and 80
SIM_SCALE = 5

def tick(args)
  $setup_done ||= false
  $cells_checked ||= 0
  $debug ||= false

  if $setup_done == false
    setup
    tick_output ||= []
    tick_output << { x: 640, y: 360, alignment_enum: 1, text: 'Loading...', r: 0,
                     g: 255, b: 0, primitive_marker: :label }
  else
    main_cycle

    $debug = !$debug if args.inputs.keyboard.key_up.tab
    if $debug
      tick_output ||= []
      tick_output << { x: 0, y: 720 - 60, w: 490, h: 60, a: 200,
                       primitive_marker: :solid }
      tick_output << { x: 0, y: 720, text: "Sim Scale: #{SIM_SCALE}", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label }
      tick_output << { x: 0, y: 700, text: "FPS: #{args.gtk.current_framerate}", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label }
      percent = (($cells_checked / ((1280 / SIM_SCALE) * (720 / SIM_SCALE))))
      tick_output << { x: 0, y: 680, text: "Cells Checked: #{$cells_checked}/#{(1280 / SIM_SCALE) * (720 / SIM_SCALE)} - #{percent}", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label }
    end
  end

  tick_output ||= nil

  $render_pixels.concat(tick_output) if tick_output
  args.outputs.primitives << $render_pixels
end

def setup
  $current_pixels ||= {}

  $iter_y ||= 0
  iter_y = $iter_y
  iter_x = 0

  $render_pixels ||= []

  if iter_y < 720
    while iter_x < 1280
      $current_pixels[iter_x] ||= {}
      if rand(2) == 1
        $render_pixels << $current_pixels[iter_x][iter_y] =
                            { x: iter_x, y: iter_y, w: SIM_SCALE, h: SIM_SCALE, path: :pixel, primitive_marker: :solid }
      end
      iter_x += SIM_SCALE
    end
    iter_y += SIM_SCALE
  end
  $iter_y = iter_y

  $setup_done = true if $iter_y >= 720
end

def main_cycle
  # Cell Neighbors
  # 123
  # 4@6
  # 789

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
        { x: curr_x - SIM_SCALE, y: curr_y - SIM_SCALE },
        { x: curr_x, y: curr_y - SIM_SCALE },
        { x: curr_x + SIM_SCALE, y: curr_y - SIM_SCALE },
        { x: curr_x - SIM_SCALE, y: curr_y },
        { x: curr_x + SIM_SCALE, y: curr_y },
        { x: curr_x - SIM_SCALE, y: curr_y + SIM_SCALE },
        { x: curr_x, y: curr_y + SIM_SCALE },
        { x: curr_x + SIM_SCALE, y: curr_y + SIM_SCALE }
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

      if neighbors == 3 || neighbors == 2

        next_tick[curr_x] ||= {}
        $render_pixels << next_tick[curr_x][curr_y] =
                            { x: curr_x, y: curr_y, w: SIM_SCALE, h: SIM_SCALE, path: :pixel,
                              primitive_marker: :solid }
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
        $render_pixels << next_tick[curr_x][curr_y] =
                            { x: curr_x, y: curr_y, w: SIM_SCALE, h: SIM_SCALE, path: :pixel,
                              primitive_marker: :solid }
      end

      iter_y -= 1
    end
    iter_x -= 1
  end

  $current_pixels = next_tick
end
