import sys

argvs = sys.argv

sample = open(argvs[1])
seed = argvs[3]

header = sample.readline()

for num in range(10):
    line = sample.readline()
    id_list = line.split('\t')[5].split(', ')
    for sample_id in id_list:
        ref = open(argvs[2])
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

        ref.close


sample.close
