FROM perl:5.40

WORKDIR /app
ADD cpanfile cpanfile.snapshot ./
RUN cpm install --local-lib-contained=/root/.local Carton::Snapshot \
 && PERL5OPT="-I/root/.local/lib/perl5" cpm install --global \
 && rm -rf cpanfile cpanfile.snapshot /root/.local
