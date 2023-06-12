#
# Train type 
#
struct Train 
    origin::Int
    destination::Int
    origin_timestamp::DateTime
    destination_timestamp::DateTime
    required_horsepower::Int 
    uuid::String 
    Train(o, d, ot, dt, hp) = new(o, d, ot, dt, hp, rand_id())
    Train(o, d, ot, dt, hp, uuid) = new(o, d, ot, dt, hp, uuid)
end 
Base.:(==)(a::Train, b::Train) = (a.uuid == b.uuid)
train_factory(hp::Int)::Train = Train(1, 1, Dates.now(), Dates.now(), hp)
update_hp!(train::Train, hp::Int)::Train = @set train.required_horsepower = hp
origin_coordinates(t::Train) = coordinates(t.origin)
destination_coordinates(t::Train) = coordinates(t.destination)
hp(t::Train) = t.required_horsepower

#
# Trains operated (raw data)
#

struct TrainOp 
    values::DataFrameRow
end 

origin_station_name_id(t::TrainOp)::String = t.values.origin_station_name_id
destination_station_name_id(t::TrainOp)::String = t.values.destination_station_name_id
origin_timestamp(t::TrainOp)::DateTime = t.values.origin_timestamp |> to_datetime
destination_timestamp(t::TrainOp)::DateTime = t.values.destination_timestamp |> to_datetime
required_horsepower(t::TrainOp)::Int = t.values.MAX_HP 
train_name_id(t::TrainOp)::String = t.values.train_name_id
train_type(t::TrainOp)::String = t.values.TRN_TYPE |> strip 
train_uuid(t::TrainOp)::String = t.values.train_uuid 
