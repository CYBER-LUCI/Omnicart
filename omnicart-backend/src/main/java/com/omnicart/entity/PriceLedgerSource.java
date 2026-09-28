package com.omnicart.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "PriceLedgerSource")
public class PriceLedgerSource {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SourceID")
    private Integer id;

    @Column(name = "SourceName", nullable = false, unique = true, length = 100)
    private String sourceName;

    public PriceLedgerSource() {}

    public PriceLedgerSource(Integer id, String sourceName) {
        this.id = id;
        this.sourceName = sourceName;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getSourceName() { return sourceName; }
    public void setSourceName(String sourceName) { this.sourceName = sourceName; }
}
