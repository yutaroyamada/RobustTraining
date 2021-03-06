require 'nn'

-- Network-in-Network
-- achieves 92% with BN and 88% without

local backend_name = 'cunn'

local backend
if backend_name == 'cudnn' then
  require 'cudnn'
  backend = cudnn
else
  backend = nn
end
  
local model = nn.Sequential()

local function Block(...)
  local arg = {...}
  model:add(backend.SpatialConvolution(...))
  model:add(nn.SpatialBatchNormalization(arg[2],1e-3))
  model:add(backend.ReLU(true))
  return model
end

Block(3,192,5,5,1,1,2,2)
Block(192,160,1,1)
Block(160,96,1,1)
model:add(backend.SpatialMaxPooling(3,3,2,2))
model:add(nn.Dropout())
Block(96,192,5,5,1,1,2,2)
Block(192,192,1,1)
Block(192,192,1,1)
model:add(backend.SpatialAveragePooling(3,3,2,2))
model:add(nn.Dropout())
Block(192,192,3,3,1,1,1,1)
Block(192,192,1,1)
Block(192,10,1,1)
model:add(backend.SpatialAveragePooling(8,8,1,1))
model:add(nn.View(10))

for k,v in pairs(model:findModules(('%s.SpatialConvolution'):format(backend_name))) do
  v.weight:normal(0,0.05)
  v.bias:zero()
end

--print(#model:cuda():forward(torch.CudaTensor(1,3,32,32)))

return model
