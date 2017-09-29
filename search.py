import sys

argvs = sys.argv

sample = open(argvs[1])
seed = argvs[3]

line = sample.readline()

while line:
    ref = open(argvs[2])
    sample_id = line.split()[0]
    content = ref.readline()

    while content:
        id_content = content.split(".")[0]
        seq_content = content.split()[-1]

        if sample_id == id_content:
            if seed in seq_content:
                print sample_id, "with-seed"
            else:
                print sample_id, "without-seed"

        content = ref.readline()

    line = sample.readline()
    ref.close

sample.close
