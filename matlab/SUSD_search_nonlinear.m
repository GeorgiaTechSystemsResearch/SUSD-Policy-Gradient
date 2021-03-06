function [K_Learned, K_hat,T_consumed]=SUSD_search_nonlinear(Q,R,x0,K_hat_0,dt,tf,tf_learning,Number_of_simulated_trajectories,window,accuracy)

%% times and gains
%--------------------------------------------------------------------------%
t_learning = 0:dt:tf_learning;
t=0:dt:tf;
K_hat=K_hat_0; 
k_n_susd=5;% The SUSD gain
%--------------------------------------------------------------------------% 
z_min=zeros(1,length(t)); %trajectory of all instantaneous minimum costs
for step =1:length(t)
        %% PCA on K_hat
        %--------------------------------------------------------------------------%
        Data = K_hat;
        Umean = mean(Data);
        R_u = Data - Umean(ones(size(Data,1),1),:);
        Covariance = R_u' * R_u;
        [Eigenvectors ,~]=eig(Covariance);
        n=Eigenvectors(:,1)';
        if step>1 && n*nold'<0
            n=-n;%to make sure there is no 180 degrees switching.
        end
        nold=n;
        %--------------------------------------------------------------------------%

        z=zeros(1,Number_of_simulated_trajectories);
        %% calculate LQR cost by runing the system forward in time
        %--------------------------------------------------------------------------%
        x=zeros(2,Number_of_simulated_trajectories,length(t_learning));
        
        for a=1:Number_of_simulated_trajectories
        x(:,a,1)=x0;
        
        end
        for i=1:Number_of_simulated_trajectories
            u=-K_hat(a,:)*x(:,a,1);
            cost=zeros(1,length(t_learning));
            cost(1,1)=x(:,i,1)'*Q*x(:,i,1)+u*R*u;
            for iteration=2:length(t_learning)
                
                x1=x(1,i,iteration-1);x2=x(2,i,iteration-1);
                x1dot=4*x2;
                x2dot=-x1^3-4*x2+u;
                xdot=[x1dot x2dot]';
                x(:,i,iteration)=x(:,i,iteration-1)+dt*xdot;
                u=-K_hat(i,:)*x(:,i,iteration);
                cost(1,iteration)=x(:,i,iteration)'*Q*x(:,i,iteration)+u*R*u;
            end
            z(1,i)=cost*ones(length(t_learning),1);

            
        end
        %--------------------------------------------------------------------------%
       zmin=min(z); %The instantaneous cost
       z_min(1,step)=zmin; %Save the instantaneous cost
       z=1-exp(-(z-zmin)); %Cost transformation
       %% Stop the search when we reach the desired accuaracy
       %--------------------------------------------------------------------------%
       if step>window
           if abs(z_min(1,step)-(1/window)*z_min(1,step-window:step-1)*ones(window,1))<accuracy
               T_consumed=t(step);
               break
           end
       end
       %--------------------------------------------------------------------------%
       %% Update the SUSD dynamics
       %--------------------------------------------------------------------------%
       for i=1:Number_of_simulated_trajectories
        K_hat_dot=k_n_susd*z(1,i)*n;% Update velocities
        K_hat(i,:)=K_hat(i,:)+dt*K_hat_dot;% Update positions  
       end
       %--------------------------------------------------------------------------% 
end
%% Return the learned cost
index_of_min=find(z==0);
K_Learned=K_hat(index_of_min,:);
end
