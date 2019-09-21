-- Copyright 2019 Stanford University
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- runs-with:
-- [ ["-fflow", "0"] ]

import "regent"

struct vec2
{
  _x : double;
  _y : double;
}

fspace fs
{
  i : int;
  v : vec2;
}

struct iface
{
  a : double;
  b : double;
}

task init_double(x : region(ispace(int1d), iface))
where reads writes(x)
do
  for e in x do
    e.a = 12345.0
    e.b = 54321.0
  end
end

task init_int(x : region(ispace(int1d), int))
where reads writes(x)
do
  for e in x do
    @e = 32123
  end
end

task sum(r : region(ispace(int1d), fs), p : int1d(fs, r)) : double
where reads(r) do
  return p.v._x + p.v._y + p.i
end

task main()
  var r = region(ispace(int1d, 5), fs)
  var x = dynamic_cast(int1d(fs, r), 2)
  var p = partition(equal, r, ispace(int1d, 2))

  __demand(__index_launch)
  for c in p.colors do
    init_double(p[c].{v})
  end
  __demand(__index_launch)
  for c in p.colors do
    init_int(p[c].{i})
  end
  regentlib.assert(sum(r, x) == 98789.0, "test failed")
end

regentlib.start(main)