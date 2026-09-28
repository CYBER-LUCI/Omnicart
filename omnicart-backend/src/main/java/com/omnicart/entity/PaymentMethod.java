package com.omnicart.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "PaymentMethod")
public class PaymentMethod {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MethodID")
    private Integer id;

    @Column(name = "MethodName", nullable = false, unique = true, length = 50)
    private String methodName;

    public PaymentMethod() {}

    public PaymentMethod(Integer id, String methodName) {
        this.id = id;
        this.methodName = methodName;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getMethodName() { return methodName; }
    public void setMethodName(String methodName) { this.methodName = methodName; }
}
