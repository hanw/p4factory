header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

action _nop() {
}

#define MAC_LEARN_RECEIVER 1024

field_list mac_learn_digest {
    ethernet.srcAddr;
    standard_metadata.ingress_port;
}

action mac_learn() {
    generate_digest(MAC_LEARN_RECEIVER, mac_learn_digest);
}

table smac {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {mac_learn; _nop;}
    size : 512;
}

action forward(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {forward; }
    size : 512;
}

control ingress {
    apply(smac);
    apply(dmac);
}

control egress {
}
