abstract type FileStorageProtocol end
struct FeatherBackend <: FileStorageProtocol end
struct ParquetBackend <: FileStorageProtocol end 

file_storage_protocol() = ParquetBackend() # default 