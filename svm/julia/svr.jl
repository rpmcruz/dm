# implementation based on Pegasos (Shwartz et al, 2007)

type SVR
    lambda     ::Float64

    # internal
    bias       ::Float64
    weights    ::Array{Float64}

    SVR(lambda) =
        new(lambda, 0, [])
end

function fit(self::SVR, X::Array{Float64,2}, y::Array{Float64})
    nobs = length(y)
    @assert size(X, 1) == nobs

    epsilon = 0.1
    maxiter = 100
    self.weights = zeros(size(X, 2))
    self.bias = 0

    # as an insipiration from resilient backpropragation, we have different
    # learning rates for each weight, which we update depending whether the
    # sign changes, i.e. we passed over the minimum (Riedmiller, 1994)
    # the strategy in Pegasus is to use eta = 1/it
    eta0 = 0.01
    old_dw = zeros(size(self.weights))
    old_db = 0
    b_eta = eta0
    w_etas = eta0 * ones(size(self.weights))
    detas = [0.5, 1, 1.2]

    for it in 1:maxiter
        dw = zeros(size(self.weights))
        db = 0

        # fix support vectors
        for i in 1:nobs
            dist = y[i] - sum((self.weights .* X[i,:]) - self.bias)
            if abs(dist) > epsilon
                s = sign(epsilon-dist)
                dw += (1/nobs) * X[i,:] * s
                db += (1/nobs) * s
            end
        end

        # penalty cost (lambda)
        dw += 2*self.lambda*self.weights

        # update learning rate
        gt_0 = old_dw .* dw .> 0
        ge_0 = old_dw .* dw .>= 0
        w_etas .*= detas[gt_0 + ge_0 + 1]

        gt_0 = old_db * db > 0
        ge_0 = old_db * db >= 0
        b_eta *= detas[gt_0 + ge_0 + 1]

        # update values
        #eta = 1/(it+2)
        self.weights -= w_etas .* dw
        self.bias -= b_eta * db
        old_dw = dw
        old_db = db
    end
    self
end

function predict(self::SVR, X::Array{Float64,2})
    a = broadcast(.*, X, self.weights')
    sum((X .* self.weights') + self.bias, 2)
end
