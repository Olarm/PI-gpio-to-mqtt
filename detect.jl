#!/home/ola/julia-1.6.2/bin/julia -t 2

using PiGPIO

my_pi=Pi()

heartbeat = 60
delay = 5

host = "192.168.68.108"
port = "1883"

pir1 = 14
pir2 = 15
num_sensors = 2
sensors = [pir1, pir2]

function f(pir, id)
    @info "spawned "*string(pir)
    topic = "verona/"*string(id)
    state = 0
    t0 = time()
    t1 = time()
    while true
	sleep(0.1)
	if PiGPIO.read(my_pi, pir) == 1
	    if state == 0 && time() - t1 < delay
		val = 1
		run(`mosquitto_pub -h $host -t $topic -m $val -q 1`)
		t0 = time()
	    	state = 1
	    elseif state == 1
		t1 = time()
	    end
	else
	    if state == 1 && time() - t1 < delay
		val = 0
		run(`mosquitto_pub -h $host -t $topic -m $val -q 1`)
		t0 = time()
	    	state = 0
	    elseif state == 0
		t1 = time()
	    end
	end
	if time() - t0 > heartbeat
	    run(`mosquitto_pub -h $host -t $topic -m $state -q 1`)
	    t0 = time()
	end
    end
end

print("threads: ", Threads.nthreads(), "\n")
Threads.@threads for i = 1:num_sensors
    print("here ", sensors[i], "\n")
    pir = sensors[i]
    f(pir, i)
end

