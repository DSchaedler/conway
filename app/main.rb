# frozen_string_literal: true

# 1; 2; 4; 5; 8; 10; 16; 20; 40 and 80
SIM_SCALE = 8

def tick(args)
  args.state.setup_done ||= false
  args.state.cells_checked ||= 0
  args.state.debug ||= false

  if args.state.setup_done == false
    setup(args)
    args.render_target(:output).primitives << { x: args.grid.center_x, y: args.grid.center_y, alignment_enum: 1, text: 'Loading...', r: 0,
                      g: 255, b: 0, primitive_marker: :label }
  else
    main_cycle(args)

    args.state.debug = !args.state.debug if args.inputs.keyboard.key_up.tab
    if args.state.debug
      args.render_target(:output).primitives << { x: args.grid.left, y: args.grid.top - 50, w: 400, h: 50, a: 200, primitive_marker: :solid }
      args.render_target(:output).primitives << { x: args.grid.left, y: args.grid.top, text: "FPS: #{args.gtk.current_framerate}", r: 0,
                        g: 0, b: 255, size: 2, primitive_marker: :label }
      perent = ((args.state.cells_checked / ((1280 / SIM_SCALE) * (720 / SIM_SCALE))) * 100).round(2)
      args.render_target(:output).primitives << { x: args.grid.left, y: args.grid.top - 20, text: "Cells Checked: #{args.state.cells_checked}/#{(1280 / SIM_SCALE) * (720 / SIM_SCALE)} - #{perent}%", r: 0,
                        g: 0, b: 255, size: 2, primitive_marker: :label }
    end
  end

  args.render_target(:output).primitives << { x: 0, y: 0, w: args.grid.w, h: args.grid.h, path: :field, primitive_marker: :sprite }
  args.outputs.primitives << { x: 0, y: 0, w: args.grid.w, h: args.grid.h, path: :output, primitive_marker: :sprite }
end

def setup(args)
  $current_pixels ||= {}

  args.state.iter_y ||= 0
  iter_y = args.state.iter_y
  iter_x = 0

  if iter_y < args.grid.h
    while iter_x < args.grid.w
      $current_pixels[iter_x] ||= {}
      $current_pixels[iter_x][iter_y] = true if rand(2) == 1
      iter_x += SIM_SCALE
    end
    iter_y += SIM_SCALE
  end
  args.state.iter_y = iter_y

  args.state.setup_done = true if args.state.iter_y >= args.grid.h

  args.render_target(:field).solids << $current_pixels.map do |x_loc, value|
    value.map do |y_loc, _state|
      { x: x_loc, y: y_loc, w: SIM_SCALE, h: SIM_SCALE, path: :pixel }
    end
  end
end

def check_neighbor(_args, current_tick, _x_iter, _y_iter, n_x, n_y)
  if current_tick.key?(n_x) && current_tick[n_x].key?(n_y)
    true
  else
    false
  end
end

def main_cycle(args)
  # Cell Neighbors
  # 123
  # 4@6
  # 789

  next_tick = {}
  dead_cells_to_check = {}
  cells_checked = 0

  $current_pixels.each_pair do |x_iter, value|
    cells_checked += value.length
    value.each_key do |y_iter|
      neighbors = 0

      n_locs = [
        { x: x_iter - SIM_SCALE, y: y_iter - SIM_SCALE },
        { x: x_iter, y: y_iter - SIM_SCALE },
        { x: x_iter + SIM_SCALE, y: y_iter - SIM_SCALE },
        { x: x_iter - SIM_SCALE, y: y_iter },
        { x: x_iter + SIM_SCALE, y: y_iter },
        { x: x_iter - SIM_SCALE, y: y_iter + SIM_SCALE },
        { x: x_iter, y: y_iter + SIM_SCALE },
        { x: x_iter + SIM_SCALE, y: y_iter + SIM_SCALE }
      ]

      n_locs.each do |location|
        break unless (location[:x]).positive? && location[:x] < args.grid.w

        break unless (location[:y]).positive? && location[:y] < args.grid.h

        if check_neighbor(args, $current_pixels, x_iter, y_iter, location[:x], location[:y])

          neighbors += 1
        else

          dead_cells_to_check[location[:x]] ||= {}
          dead_cells_to_check[location[:x]][location[:y]] = false
        end
      end

      if [3, 2].include?(neighbors)
        next_tick[x_iter] ||= {}
        next_tick[x_iter][y_iter] = true
      end
    end
  end

  dead_cells_to_check.each_pair do |x_iter, value|
    cells_checked += value.length
    value.each_key do |y_iter|
      cells_checked += 1
      neighbors = 0

      n_locs = [
        { x: x_iter - SIM_SCALE, y: y_iter - SIM_SCALE },
        { x: x_iter, y: y_iter - SIM_SCALE },
        { x: x_iter + SIM_SCALE, y: y_iter - SIM_SCALE },
        { x: x_iter - SIM_SCALE, y: y_iter },
        { x: x_iter + SIM_SCALE, y: y_iter },
        { x: x_iter - SIM_SCALE, y: y_iter + SIM_SCALE },
        { x: x_iter, y: y_iter + SIM_SCALE },
        { x: x_iter + SIM_SCALE, y: y_iter + SIM_SCALE }
      ]

      n_locs.each do |location|
        break unless (location[:x]).positive? && location[:x] < args.grid.w
        break unless (location[:y]).positive? && location[:y] < args.grid.h

        neighbors += 1 if check_neighbor(args, $current_pixels, x_iter, y_iter, location[:x], location[:y])
      end

      if neighbors == 3
        next_tick[x_iter] ||= {}
        next_tick[x_iter][y_iter] = true
      end
    end
  end

  $current_pixels = next_tick
  args.state.cells_checked = cells_checked

  args.render_target(:field).solids << next_tick.map do |x_loc, value|
    value.map do |y_loc, _state|
      { x: x_loc, y: y_loc, w: SIM_SCALE, h: SIM_SCALE, path: :pixel }
    end
  end
end
