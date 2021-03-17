CXX = g++-10
MPICXX = mpicxx

# use -xmic-avx512 instead of -xHost for Intel Xeon Phi platforms
OPTFLAGS = -O3 -DPRINT_DIST_STATS -DPRINT_EXTRA_NEDGES
# -DPRINT_EXTRA_NEDGES prints extra edges when -p <> is passed to 
#  add extra edges randomly on a generated graph
# use export ASAN_OPTIONS=verbosity=1 to check ASAN output
SNTFLAGS = -std=c++11 -fsanitize=address -O1 -fno-omit-frame-pointer
CXXFLAGS = -std=c++11 -g -I. $(OPTFLAGS)

ENABLE_DUMPI_TRACE=0
ENABLE_SCOREP_TRACE=0
ifeq ($(ENABLE_DUMPI_TRACE),1)
	TRACERPATH = $(HOME)/builds/sst-dumpi/lib 
	LDFLAGS = -L$(TRACERPATH) -ldumpi
else ifeq ($(ENABLE_SCOREP_TRACE),1)
	SCOREP_INSTALL_PATH = /usr/common/software/scorep/6.0/intel
	INCLUDE = -I$(SCOREP_INSTALL_PATH)/include -I$(SCOREP_INSTALL_PATH)/include/scorep -DSCOREP_USER_ENABLE
	LDAPP = $(SCOREP_INSTALL_PATH)/bin/scorep --user --nocompiler --noopenmp --nopomp --nocuda --noopenacc --noopencl --nomemory
endif

ENABLE_SSTMACRO=0
ifeq ($(ENABLE_SSTMACRO),1)
    SSTPATH = $(HOME)/builds/sst-macro
    CXX = $(SSTPATH)/bin/sst++
    CXXFLAGS += -fPIC -DSSTMAC -I$(SSTPATH)/include
    LDFLAGS = -Wl,-rpath,$(SSTPATH)/lib
endif

OBJ_MPI = main.o
SRC_MPI = main.cpp
TARGET_MPI = neve_mpi 
OBJ_THREADS = main_threads.o
SRC_THREADS = main_threads.cpp
TARGET_THREADS = neve_threads

OBJS = $(OBJ_MPI) $(OBJ_THREADS)
TARGETS = $(TARGET_MPI) $(TARGET_THREADS)

all: $(TARGETS)
mpi: $(TARGET_MPI)
threads: $(TARGET_THREADS)

$(TARGET_MPI):  $(OBJ_MPI)
	$(LDAPP) $(MPICXX) -o $@ $+ $(LDFLAGS) $(CXXFLAGS) 

$(OBJ_MPI): $(SRC_MPI)
	$(MPICXX) $(INCLUDE) $(CXXFLAGS) -c $< -o $@

$(TARGET_THREADS):  $(OBJ_THREADS)
	$(LDAPP) $(CXX) -fopenmp -DUSE_SHARED_MEMORY -DGRAPH_FT_LOAD=1 -o $@ $+ $(LDFLAGS) $(CXXFLAGS) 

$(OBJ_THREADS): $(SRC_THREADS)
	$(CXX) $(INCLUDE) $(CXXFLAGS) -fopenmp -DUSE_SHARED_MEMORY -DGRAPH_FT_LOAD=1 -c $< -o $@

.PHONY: clean mpi threads

clean:
	rm -rf *~ *.dSYM nc.vg.* $(OBJS) $(TARGETS)
