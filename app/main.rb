# frozen_string_literal: true

# 1; 2; 4; 5; 8; 10; 16; 20; 40 and 80
SIM_SCALE = 8

def tick(args)
  $setup_done ||= false
  $cells_checked ||= 0
  $debug ||= false

  tick_output = []

  if $setup_done == false
    setup(args)
    tick_output << { x: args.grid.center_x, y: args.grid.center_y, alignment_enum: 1, text: 'Loading...', r: 0,
                     g: 255, b: 0, primitive_marker: :label }
  else
    main_cycle(args)

    $debug = !$debug if args.inputs.keyboard.key_up.tab
    if $debug
      tick_output << { x: args.grid.left, y: args.grid.top - 50, w: 400, h: 50, a: 200,
                       primitive_marker: :solid }
      tick_output << { x: args.grid.left, y: args.grid.top, text: "FPS: #{args.gtk.current_framerate}", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label }
      perent = (($cells_checked / ((1280 / SIM_SCALE) * (720 / SIM_SCALE))) * 100).round(2)
      tick_output << { x: args.grid.left, y: args.grid.top - 20, text: "Cells Checked: #{$cells_checked}/#{(1280 / SIM_SCALE) * (720 / SIM_SCALE)} - #{perent}%", r: 0,
                       g: 0, b: 255, size: 2, primitive_marker: :label }
    end
  end

  args.outputs.primitives << $render_pixels
  args.outputs.primitives << tick_output
end

def setup(args)
  $current_pixels ||= {}

  $iter_y ||= 0
  iter_y = $iter_y
  iter_x = 0

  $render_pixels ||= []

  if iter_y < args.grid.h
    while iter_x < args.grid.w
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

  $setup_done = true if $iter_y >= args.grid.h
end

def main_cycle(args)
  # Cell Neighbors
  # 123
  # 4@6
  # 789

  next_tick = {}
  dead_cells_to_check = {}
  cells_checked = 0

  $render_pixels = []

  iter_x = $current_pixels.length - 1

  while iter_x >= 0
    iter_y = $current_pixels.values[iter_x].length - 1
    cells_checked += iter_y
    while iter_y >= 0
      curr_x = $current_pixels.keys[iter_x]
      curr_y = $current_pixels.values[iter_x].keys[iter_y]
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

      while location_iter < n_locs.length
        location = n_locs[location_iter]
        location_iter += 1
        if (location[:x]).positive? && location[:x] < args.grid.w && (location[:y]).positive? && location[:y] < args.grid.h
          if $current_pixels.key?(location[:x]) && $current_pixels[location[:x]].key?(location[:y])
            neighbors += 1
          else
            dead_cells_to_check[location[:x]] ||= {}
            dead_cells_to_check[location[:x]][location[:y]] = false
          end
        end
      end

      if [3, 2].include?(neighbors)

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

  while iter_x >= 0
    iter_y = dead_cells_to_check.values[iter_x].length - 1
    cells_checked += iter_y
    while iter_y >= 0
      curr_x = dead_cells_to_check.keys[iter_x]
      curr_y = dead_cells_to_check.values[iter_x].keys[iter_y]
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

      while location_iter < n_locs.length
        location = n_locs[location_iter]
        location_iter += 1
        unless (location[:x]).positive? && location[:x] < args.grid.w && (location[:y]).positive? && location[:y] < args.grid.h
          next
        end

        neighbors += 1 if $current_pixels.key?(location[:x]) && $current_pixels[location[:x]].key?(location[:y])
      end

      if neighbors == 3

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
  $cells_checked = cells_checked
end
